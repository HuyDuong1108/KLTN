"""
AI Gateway + SRS API for LinguaSquirrel.

Endpoints (5):

1) POST /srs/review
   - Body: { "card_id": "...", "rating": 1..4 }  (cũng chấp nhận "cardId")
   - Dùng FSRS (srs_engine.py) để tính lịch,
     cập nhật user_card_progress.json + review_logs.jsonl.

2) POST /ai/chat
   - Body: { "question": "..." }
   - Trả: { "answer": "...", "sources": [] }
   - Dùng Gemini 2.5 Flash nếu có GEMINI_API_KEY, nếu không thì mock.

3) POST /ai/flashcard/suggest
   - Body: { "term": "...", "language": "chinese" }
   - Trả:
       {
         "term": "...",
         "reading": "...",
         "pos": "...",
         "translations": [...],
         "example": {
           "sentence": "...",
           "reading": "...",
           "translation": "..."
         },
         "image_suggestions": [...]
       }
   - Dùng Gemini nếu có key, nếu không thì mock.

4) POST /ai/examples/generate
   - MOCK đơn giản, không gọi LLM:
       Body: { "term": "...", "language": "chinese" }
       → trả vài ví dụ cứng.

5) GET /ai/learning/insights
   - Đọc review_logs.jsonl (nếu có),
     trả tổng quan rating:
       {
         "total_reviews": N,
         "by_rating": { "1": n1, "2": n2, "3": n3, "4": n4 }
       }

Timezone: toàn bộ log FSRS = UTC (chuẩn với srs_engine.py).
"""

from __future__ import annotations

import os, re
import json
from pathlib import Path
from datetime import timezone, datetime, timedelta, date
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI, HTTPException, Header, Depends, Query

import google.generativeai as genai

from srs_engine import (
    load_scheduler_from_config,
    load_cards,
    review as srs_review_core,
    save_progress,
    log_review,
)
# import và khởi tạo Firebase Admin 
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore as admin_firestore

# -----------------------------
# App & paths
# -----------------------------
app = FastAPI(title="LinguaSquirrel AI Gateway + SRS")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
BASE_DIR = Path(__file__).parent
DATA_ROOT = BASE_DIR / "data"

FSRS_CFG_PATH = DATA_ROOT / "fsrs_scheduler_optimized.json"
CARDS_PATH = DATA_ROOT / "cards_text_only.json"
PROGRESS_PATH = DATA_ROOT / "user_card_progress.json"
REVIEW_LOGS_PATH = DATA_ROOT / "review_logs.jsonl"

# -----------------------------
# FSRS init
# -----------------------------
scheduler = load_scheduler_from_config(FSRS_CFG_PATH)
#cards_registry = load_cards(CARDS_PATH, PROGRESS_PATH)

# -----------------------------
# Gemini init (AI)
# -----------------------------
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_MODEL_NAME = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    try:
        gemini_model = genai.GenerativeModel(GEMINI_MODEL_NAME)
    except Exception:
        # Nếu cấu hình model lỗi, fallback mock
        gemini_model = None
else:
    gemini_model = None  # không có key → luôn dùng mock

# ============================================================
# STORAGE MODE
# - local: dùng file data/users/{uid}/...
# - firestore: đồng bộ progress/log lên Firestore theo uid
# ============================================================
STORAGE_MODE = os.getenv("STORAGE_MODE", "local").strip().lower()
USE_FIRESTORE = STORAGE_MODE == "firestore"

db = None
if USE_FIRESTORE:
    FIREBASE_KEY_PATH = os.getenv(
        "FIREBASE_KEY_PATH",
        str(BASE_DIR / "serviceAccountKey.json"),
    )
    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(FIREBASE_KEY_PATH))
    db = admin_firestore.client()


def _fs_progress_doc(uid: str):
    # users/{uid}/srs/progress
    return db.collection("users").document(uid).collection("srs").document("progress")


def _fs_reviews_col(uid: str):
    # users/{uid}/srs_reviews/{autoId}
    return db.collection("users").document(uid).collection("srs_reviews")


# update : tạo log userID
USERS_ROOT = DATA_ROOT / "users"
_registry_cache: Dict[str, Any] = {}  # uid -> registry

def _require_uid(x_user_id: Optional[str]) -> str:
    uid = (x_user_id or "").strip()
    if not uid:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")
    return uid

# thêm để test 
def _require_uid2(x_user_id: Optional[str], uid_q: Optional[str]) -> str:
    uid = (x_user_id or "").strip()
    if not uid:
        uid = (uid_q or "").strip()
    if not uid:
        raise HTTPException(status_code=401, detail="Missing X-User-Id")
    return uid

def _user_paths(uid: str) -> Dict[str, Path]:
    udir = USERS_ROOT / uid
    udir.mkdir(parents=True, exist_ok=True)
    return {
        "progress": udir / "user_card_progress.json",
        "logs": udir / "review_logs.jsonl",
    }

def _fs_download_progress_to_file(uid: str, progress_path: Path) -> None:
    """
    Firestore -> local file (để reuse load_cards/save_progress hiện tại)
    """
    snap = _fs_progress_doc(uid).get()
    if not snap.exists:
        # chưa có thì tạo file rỗng
        if not progress_path.exists():
            progress_path.write_text("{}", encoding="utf-8")
        return

    data = snap.to_dict() or {}
    raw = data.get("progress_json")
    if not raw:
        progress_path.write_text("{}", encoding="utf-8")
        return
    progress_path.write_text(raw, encoding="utf-8")

def _fs_upload_progress_file(uid: str, progress_path: Path) -> None:
    """
    local file -> Firestore
    """
    raw = progress_path.read_text(encoding="utf-8") if progress_path.exists() else "{}"
    _fs_progress_doc(uid).set(
        {
            "progress_json": raw,
            "updatedAt": admin_firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )
# update review log payload  
def _reviewlog_payload(card_id: str, rating: int, rlog: Any) -> Dict[str, Any]:
    dt = getattr(rlog, "review_datetime", None)
    if isinstance(dt, datetime):
        ts_dt = dt.astimezone(timezone.utc)
    else:
        ts_dt = datetime.now(timezone.utc)

    duration = getattr(rlog, "review_duration", None)
    duration_ms: Optional[int] = None
    if isinstance(duration, (int, float)):
        duration_ms = int(duration * 1000)

    return {
        "cardId": str(card_id),
        "rating": int(rating),

        # Firestore nên lưu Timestamp:
        "ts": ts_dt,

        # giữ thêm bản ISO để dễ nhìn/log:
        "tsIso": ts_dt.isoformat().replace("+00:00", "Z"),

        "durationMs": duration_ms,
    }

def _fs_add_review(uid: str, card_id: str, rlog: Dict[str, Any], rating: int) -> None:
    """
    Ghi review log lên Firestore (1 doc / review)
    """
    payload = _reviewlog_payload(card_id=card_id, rating=rating, rlog=rlog)
    _fs_reviews_col(uid).add(payload)

def _get_registry(uid: str):
    """
    Registry load theo uid.
    - local mode: load_cards(CARDS_PATH, users/{uid}/progress.json)
    - firestore mode: sync progress Firestore -> file -> load_cards()
    """
    paths = _user_paths(uid)

    # firestore mode: luôn sync xuống để data mới nhất (đỡ cache sai)
    if USE_FIRESTORE:
        _fs_download_progress_to_file(uid, paths["progress"])
        return load_cards(CARDS_PATH, paths["progress"])

    # local mode: cache
    if uid not in _registry_cache:
        _registry_cache[uid] = load_cards(CARDS_PATH, paths["progress"])
    return _registry_cache[uid]



# ============================================================
# 1) SRS /review
# ============================================================

class SrsReviewRequest(BaseModel):
    cardId: Optional[str] = None
    card_id: Optional[str] = None
    rating: int  # 1..4


class SrsReviewResponse(BaseModel):
    cardId: str
    due: Optional[str]
    state: str
    card_json: str


@app.post("/srs/review", response_model=SrsReviewResponse)
def srs_review(
    req: SrsReviewRequest,
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
    ) -> SrsReviewResponse:

    uid = _require_uid(x_user_id)
    paths = _user_paths(uid)
    registry = _get_registry(uid)

    card_id = req.cardId or req.card_id
    if not card_id:
        raise HTTPException(
            status_code=400,
            detail="cardId or card_id is required",
        )

    try:
        card, rlog = srs_review_core(
            card_id=card_id,
            rating=req.rating,
            scheduler=scheduler,
            registry=registry,
        )
    except ValueError as e:
        # rating không hợp lệ (không phải 1..4) thì vẫn bắn 400
        raise HTTPException(status_code=400, detail=str(e))


    # Lưu tiến độ & log
    save_progress(paths["progress"], registry)
    log_review(paths["logs"], card_id, rlog)

    if USE_FIRESTORE:
        _fs_upload_progress_file(uid, paths["progress"])
        _fs_add_review(uid, card_id, rlog, req.rating)

    # Chuẩn hóa due -> ISO UTC 'Z'
    due = card.due
    if due is not None:
        if due.tzinfo is None:
            due = due.replace(tzinfo=timezone.utc)
        else:
            due = due.astimezone(timezone.utc)
        due_str = due.isoformat().replace("+00:00", "Z")
    else:
        due_str = None

    state_str = getattr(card.state, "name", str(card.state))

    return SrsReviewResponse(
        cardId=card_id,
        due=due_str,
        state=state_str,
        card_json=card.to_json(),
    )


# ============================================================
# 2) /ai/chat
# ============================================================

class AiChatRequest(BaseModel):
    question: str


class AiChatResponse(BaseModel):
    answer: str
    sources: List[Dict[str, Any]]


def _ai_chat_mock(question: str) -> AiChatResponse:
    """
    Fallback khi không có GEMINI_API_KEY.
    Contract giữ y như Flutter đang dùng.
    """
    return AiChatResponse(
        answer=f"[mock] Hỏi: {question}",
        sources=[],
    )


@app.post("/ai/chat", response_model=AiChatResponse)
def ai_chat(req: AiChatRequest) -> AiChatResponse:
    if gemini_model is None:
        return _ai_chat_mock(req.question)

    prompt = (
        "Bạn là trợ lý giải thích ngữ pháp và từ vựng tiếng Anh "
        "cho người học tiếng Việt. Trả lời ngắn gọn, rõ ràng, "
        "kèm phiên âm pinyin nếu cần.\n\n"
        f"Câu hỏi của người dùng: {req.question}"
    )

    try:
        result = gemini_model.generate_content(prompt)
        text = result.text.strip() if result and result.text else ""
        if not text:
            return _ai_chat_mock(req.question)
        return AiChatResponse(answer=text, sources=[])
    except Exception:
        # Nếu call Gemini lỗi, fallback mock
        return _ai_chat_mock(req.question)


# ============================================================
# 3) /ai/flashcard/suggest
# ============================================================

class AiFlashcardSuggestRequest(BaseModel):
    term: str
    language: str = "chinese"


class ExamplePayload(BaseModel):
    sentence: str
    reading: str
    translation: str


class AiFlashcardSuggestResponse(BaseModel):
    term: str
    reading: str
    pos: str
    translations: List[str]
    example: ExamplePayload
    image_suggestions: List[str]


def _ai_suggest_mock(term: str, language: str) -> AiFlashcardSuggestResponse:
    """
    Fallback đơn giản, giữ contract giống mock trên Flutter.
    """
    return AiFlashcardSuggestResponse(
        term=term,
        reading="",
        pos="(unknown)",
        translations=[term],
        example=ExamplePayload(
            sentence="(mock) 这是一个例句。",
            reading="(mock) zhè shì yí gè lìjù.",
            translation=f"(mock) Ví dụ với từ: {term}",
        ),
        image_suggestions=[f"keyword: {term}"],
    )


@app.post(
    "/ai/flashcard/suggest",
    response_model=AiFlashcardSuggestResponse,
)
def ai_flashcard_suggest(
    req: AiFlashcardSuggestRequest,
) -> AiFlashcardSuggestResponse:
    term = req.term.strip()
    if not term:
        raise HTTPException(
            status_code=400,
            detail="`term` is required",
        )

    if gemini_model is None:
        return _ai_suggest_mock(term, req.language)

    sys_prompt = (
        "Bạn là trợ lý tạo flashcard tiếng Anh cho người học tiếng Việt. "
        "Cho một từ (term), hãy trả về JSON với các trường:\n"
        "term, reading (pinyin), pos, translations (tiếng Việt, 1-3 mục), "
        "example {sentence, reading, translation}, "
        "image_suggestions (1-3 gợi ý từ khóa tiếng Anh để tìm ảnh).\n\n"
        "Chỉ trả về JSON, không kèm giải thích."
    )

    user_prompt = f"term: {term}\nlanguage: {req.language}"

    try:
        result = gemini_model.generate_content(
            [
                sys_prompt,
                "\n\n---\n\n",
                user_prompt,
            ]
        )
        raw = result.text if result and result.text else ""
        if not raw:
            return _ai_suggest_mock(term, req.language)

        # Thử parse JSON từ câu trả lời
        # Để an toàn, strip code block ``` nếu có
        raw_str = raw.strip()
        if raw_str.startswith("```"):
            # loại bỏ ```json ... ```
            raw_str = raw_str.strip("`")
            # có thể còn "json\n{...}"
            if raw_str.lower().startswith("json"):
                raw_str = raw_str[4:].strip()

        data = json.loads(raw_str)

        # Chuẩn hóa field & fallback nếu thiếu
        reading = data.get("reading", "")
        pos = data.get("pos", "(unknown)")
        translations = data.get("translations") or [term]
        example_data = data.get("example") or {}
        example = ExamplePayload(
            sentence=example_data.get("sentence", ""),
            reading=example_data.get("reading", ""),
            translation=example_data.get("translation", ""),
        )
        image_suggestions = data.get("image_suggestions") or [
            f"keyword: {term}"
        ]

        return AiFlashcardSuggestResponse(
            term=term,
            reading=reading,
            pos=pos,
            translations=translations,
            example=example,
            image_suggestions=image_suggestions,
        )

    except Exception:
        # Bất kỳ lỗi nào (parse JSON, call LLM, ...) → fallback mock
        return _ai_suggest_mock(term, req.language)


# ============================================================
# 4) /ai/examples/generate (mock)
# ============================================================

class AiExamplesRequest(BaseModel):
    term: str
    language: str = "chinese"


class AiExamplesResponse(BaseModel):
    term: str
    language: str
    examples: List[ExamplePayload]


@app.post("/ai/examples/generate", response_model=AiExamplesResponse)
def ai_examples_generate(req: AiExamplesRequest) -> AiExamplesResponse:
    """
    MOCK: không gọi LLM, chỉ trả vài ví dụ cứng.
    Có thể nâng cấp sau, nhưng contract giữ ổn định.
    """
    term = req.term.strip()
    if not term:
        raise HTTPException(
            status_code=400,
            detail="`term` is required",
        )

    examples = [
        ExamplePayload(
            sentence=f"{term} 真的很重要。",
            reading=f"{term} zhēn de hěn zhòngyào.",
            translation=f"{term} thực sự rất quan trọng.",
        ),
        ExamplePayload(
            sentence=f"我每天都在用 {term}。",
            reading=f"Wǒ měitiān dōu zài yòng {term}.",
            translation=f"Tôi dùng {term} mỗi ngày.",
        ),
    ]

    return AiExamplesResponse(
        term=term,
        language=req.language,
        examples=examples,
    )


# ============================================================
# 5) /ai/learning/insights V1 (tổng quan rating)
# ============================================================

class AiInsightsSummary(BaseModel):
    total_reviews: int
    by_rating: Dict[str, int]


@app.get("/ai/learning/insights", response_model=AiInsightsSummary)
def ai_learning_insights(
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
) -> AiInsightsSummary:
    uid = _require_uid(x_user_id)
    paths = _user_paths(uid)
    logs_path = paths["logs"]

    """
    V1: tổng quan rating từ review_logs.jsonl.

    - Đọc từng dòng JSON: {"cardId","rating","ts"}
    - Đếm số lượng từng rating (1..4).
    - Trả về tổng quan: total_reviews & by_rating.
    """
    total = 0
    by_rating: Dict[str, int] = {"1": 0, "2": 0, "3": 0, "4": 0}

    if USE_FIRESTORE:
    # đọc toàn bộ logs (MVP)
        for doc in _fs_reviews_col(uid).stream():
            row = doc.to_dict() or {}
            r = int(row.get("rating", 0))
            if r in (1, 2, 3, 4):
                total += 1
                by_rating[str(r)] += 1
        return AiInsightsSummary(total_reviews=total, by_rating=by_rating)
    
    if not logs_path.exists():
        # NOTE: nếu thiếu dữ liệu thật → trả 0, không lỗi.
        return AiInsightsSummary(total_reviews=0, by_rating=by_rating)

    with logs_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
                r = int(row.get("rating", 0))
                if r in (1, 2, 3, 4):
                    total += 1
                    by_rating[str(r)] = by_rating.get(str(r), 0) + 1
            except Exception:
                # Bỏ qua dòng hỏng
                continue

    return AiInsightsSummary(total_reviews=total, by_rating=by_rating)

@app.get("/health")
def health():
    return {"ok": True}

# ============================================================
# 6) /stats/summary (thống kê tiến độ)
#    - Lấy từ cards_registry (FSRS state/due) + review_logs.jsonl
# ============================================================

class DueBucket(BaseModel):
    day: str  # YYYY-MM-DD
    count: int

# class StatsSummaryResponse(BaseModel):
#     cards_total: int
#     cards_by_state: Dict[str, int]
#     due_now: int
#     due_today: int
#     due_next_7d: List[DueBucket]

#     reviews_total: int
#     reviews_by_rating: Dict[str, int]
#     reviews_last_7d: int
#     success_rate_7d: float  # (rating 3,4) / total_last_7d, nếu không có thì 0
#     days_active_total: int          # số ngày có review (all time)
#     streak_current: int             # streak tính tới hôm nay (UTC)
#     xp_total: int                   # XP all time
#     success_rate_all_time: float    # (rating 3,4) / total all time

def _safe_state_name(card: Any) -> str:
    st = getattr(card, "state", None)
    if st is None:
        return "New"
    return getattr(st, "name", str(st))

def _safe_due_utc(card: Any) -> Optional[datetime]:
    due = getattr(card, "due", None)
    if due is None:
        return None
    if getattr(due, "tzinfo", None) is None:
        return due.replace(tzinfo=timezone.utc)
    return due.astimezone(timezone.utc)

def _parse_ts(row: Dict[str, Any]) -> Optional[datetime]:
    ts = row.get("ts") or row.get("timestamp") or row.get("time")
    if not ts:
        return None

    s = str(ts).strip()

    # hỗ trợ "...Z"
    if s.endswith("Z"):
        s = s[:-1]

    # hỗ trợ cả "YYYY-MM-DD HH:MM:SS.ffffff" và "YYYY-MM-DDTHH:MM:SS.ffffff"
    s = s.replace("T", " ")

    # thử parse với microseconds trước, fallback không microseconds
    for fmt in ("%Y-%m-%d %H:%M:%S.%f", "%Y-%m-%d %H:%M:%S"):
        try:
            dt = datetime.strptime(s, fmt)
            return dt.replace(tzinfo=timezone.utc)
        except Exception:
            pass

    # fallback cuối
    try:
        dt = datetime.fromisoformat(s)
        return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt.astimezone(timezone.utc)
    except Exception:
        return None
def _xp_for_rating(r: int) -> int:
    return {1: 0, 2: 5, 3: 10, 4: 15}.get(r, 0)

def _calc_streak(dates_set: set[date], today: date) -> int:
    if not dates_set:
        return 0
    base = today if today in dates_set else today - timedelta(days=1)
    streak = 0
    d = base
    while d in dates_set:
        streak += 1
        d = d - timedelta(days=1)
    return streak
def _load_review_events(uid: str, tz_offset_min: int) -> List[Dict[str, Any]]:
    """
    Load review events (UTC + local shifted) từ local file hoặc Firestore.
    Output:
      { "ts_utc": datetime, "ts_local": datetime, "cardId": str, "rating": int }
    """
    paths = _user_paths(uid)
    logs_path = paths["logs"]
    events: List[Dict[str, Any]] = []

    def push(ts_dt: Optional[datetime], card_id: str, r: int):
        if ts_dt is None:
            return
        if ts_dt.tzinfo is None:
            ts_dt = ts_dt.replace(tzinfo=timezone.utc)
        else:
            ts_dt = ts_dt.astimezone(timezone.utc)

        events.append(
            {
                "ts_utc": ts_dt,
                "ts_local": _shift_tz(ts_dt, tz_offset_min),
                "cardId": str(card_id),
                "rating": int(r),
            }
        )

    if USE_FIRESTORE:
        for doc in _fs_reviews_col(uid).stream():
            row = doc.to_dict() or {}
            r = int(row.get("rating", 0))
            card_id = row.get("cardId") or row.get("card_id") or ""
            ts = row.get("ts")

            ts_dt: Optional[datetime] = None
            if hasattr(ts, "datetime"):
                ts_dt = ts.datetime.replace(tzinfo=timezone.utc)
            elif isinstance(ts, datetime):
                ts_dt = ts.astimezone(timezone.utc)
            elif isinstance(ts, str):
                ts_dt = _parse_ts({"ts": ts})

            if r in (1, 2, 3, 4):
                push(ts_dt, str(card_id), r)
        return events

    if logs_path.exists():
        with logs_path.open("r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                    r = int(row.get("rating", 0))
                    card_id = row.get("cardId") or row.get("card_id") or ""
                    ts_dt = _parse_ts(row)
                    if r in (1, 2, 3, 4):
                        push(ts_dt, str(card_id), r)
                except Exception:
                    continue

    return events

def _shift_tz(dt: datetime, tz_offset_min: int) -> datetime:
    return dt + timedelta(minutes=int(tz_offset_min or 0))

class StatsSummaryResponse(BaseModel):
    cards_total: int
    cards_by_state: Dict[str, int]
    due_now: int
    due_today: int
    due_next_7d: List[DueBucket]

    reviews_total: int
    reviews_by_rating: Dict[str, int]
    reviews_last_7d: int
    success_rate_7d: float
    days_active_total: int
    streak_current: int
    xp_total: int
    success_rate_all_time: float

    horizon_days: int = 7
    last_review_ts: Optional[str] = None
    hours_since_last_review: Optional[float] = None
    streak_level: int = 0  # 3:🔥 2:🟠 1:🟡 0:⚫


@app.get("/stats/summary", response_model=StatsSummaryResponse)
def stats_summary(
    horizon_days: int = Query(7, alias="horizonDays"),
    tz_offset_min: int = Query(0, alias="tz_offset_min"),
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
) -> StatsSummaryResponse:
    uid = _require_uid(x_user_id)
    paths = _user_paths(uid)
    logs_path = paths["logs"]
    registry = _get_registry(uid)

    horizon_days = max(1, min(int(horizon_days), 60))
    tz_offset_min = int(tz_offset_min or 0)
    tz_offset_min = max(-720, min(tz_offset_min, 840))
    now = datetime.now(timezone.utc)
    local_now = _shift_tz(now, tz_offset_min)
    local_today = local_now.date()

    # ---------- Card stats (state/due) ----------
    cards_by_state: Dict[str, int] = {}
    due_now = 0
    due_today = 0

    # buckets 7 ngày tới (tính từ hôm nay)
    buckets: Dict[date, int] = {local_today + timedelta(days=i): 0 for i in range(horizon_days)}

    # cards_registry là dict card_id -> Card
    for _cid, card in registry.items():
        st = _safe_state_name(card)
        cards_by_state[st] = cards_by_state.get(st, 0) + 1

        due = _safe_due_utc(card)
        if due is None:
            continue
        
        due_local = _shift_tz(due, tz_offset_min)

        if due_local <= local_now:
            due_now += 1
        if due_local.date() == local_today:
            due_today += 1
        if due_local.date() in buckets:
            buckets[due_local.date()] += 1

    due_next_7d = [
        DueBucket(day=d.isoformat(), count=buckets[d])
        for d in sorted(buckets.keys())
    ]

    # ---------- Review log stats ----------
    reviews_total = 0
    reviews_by_rating: Dict[str, int] = {"1": 0, "2": 0, "3": 0, "4": 0}
    reviews_last_7d = 0
    good_easy_last_7d = 0
    dates_active: set = set()     # set of date (UTC)
    xp_total = 0
    good_easy_all = 0

    dates_active_local: set[date] = set()
    cutoff = now - timedelta(days=7)

    last_review_dt: Optional[datetime] = None
    
    def ingest(ts: Optional[datetime], r: int):
        nonlocal reviews_total, reviews_last_7d, good_easy_last_7d, xp_total, good_easy_all, last_review_dt
        if r in (1, 2, 3, 4):
            reviews_total += 1
            reviews_by_rating[str(r)] += 1
            xp_total += _xp_for_rating(r)
            if r in (3, 4):
                good_easy_all += 1

        if ts:
            if last_review_dt is None or ts > last_review_dt:
                last_review_dt = ts
            dates_active_local.add(_shift_tz(ts, tz_offset_min).date())

        if ts and ts >= cutoff and r in (1, 2, 3, 4):
            reviews_last_7d += 1
            if r in (3, 4):
                good_easy_last_7d += 1

    if USE_FIRESTORE:
        for doc in _fs_reviews_col(uid).stream():
            row = doc.to_dict() or {}
            r = int(row.get("rating", 0))
            ts = row.get("ts")

            ts_dt: Optional[datetime] = None
            if hasattr(ts, "datetime"):
                ts_dt = ts.datetime.replace(tzinfo=timezone.utc)
            elif isinstance(ts, datetime):
                ts_dt = ts.astimezone(timezone.utc)
            elif isinstance(ts, str):
                ts_dt = _parse_ts({"ts": ts})

            ingest(ts_dt, r)

    else:
        if logs_path.exists():
            with logs_path.open("r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        row = json.loads(line)
                        r = int(row.get("rating", 0))
                        ts_dt = _parse_ts(row)
                        ingest(ts_dt, r)
                    except Exception:
                        continue

    success_rate_7d = (
        (good_easy_last_7d / reviews_last_7d) if reviews_last_7d > 0 else 0.0
    )
    days_active_total = len(dates_active_local)
    streak_current = _calc_streak(dates_active_local, local_today)

    success_rate_all_time = (good_easy_all / reviews_total) if reviews_total > 0 else 0.0

    last_review_ts = _iso_utc_z(last_review_dt) if last_review_dt else None
    hours_since = ((now - last_review_dt).total_seconds() / 3600.0) if last_review_dt else None

    # streak_level theo “nghỉ 24h/48h/1 tuần”
    if hours_since is None:
        streak_level = 0
    elif hours_since <= 24:
        streak_level = 3
    elif hours_since <= 48:
        streak_level = 2
    elif hours_since <= 24 * 7:
        streak_level = 1
    else:
        streak_level = 0

    return StatsSummaryResponse(
        cards_total=len(registry),
        cards_by_state=cards_by_state,
        due_now=due_now,
        due_today=due_today,
        due_next_7d=due_next_7d,
        reviews_total=reviews_total,
        reviews_by_rating=reviews_by_rating,
        reviews_last_7d=reviews_last_7d,
        success_rate_7d=success_rate_7d,
        days_active_total=days_active_total,
        streak_current=streak_current,
        xp_total=xp_total,
        success_rate_all_time=success_rate_all_time,
        horizon_days=horizon_days,
        last_review_ts=last_review_ts,
        hours_since_last_review=hours_since,
        streak_level=streak_level,
    )

# mới thêm : 
class DueCardMatch(BaseModel):
    tab: str              # "personal" | "community"
    setId: str
    setTitle: str
    setSource: Optional[Dict[str, Any]] = None  # <-- NEW (learning metadata)
    word: str
    reading: Optional[str] = None               # giữ tên "reading" cho FE, nhưng fill từ romaji
    meaning: Optional[str] = None
    imageUrl: Optional[str] = None   

class DueCardDetailItem(BaseModel):
    cardId: str
    due: Optional[str] = None      # ISO UTC 'Z'
    state: str
    matches: List[DueCardMatch] = []

class DueCardsDetailResponse(BaseModel):
    scope: str            # "now" | "today"
    total: int            # tổng số thẻ đến hạn (khớp due_now/due_today nếu limit đủ lớn)
    items: List[DueCardDetailItem]
def _extract_vocab_list(raw: Any) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    if isinstance(raw, list):
        for e in raw:
            if isinstance(e, dict):
                out.append(e)
    elif isinstance(raw, dict):
        for e in raw.values():
            if isinstance(e, dict):
                out.append(e)
    return out
def _norm_card_key(x: Any) -> str:
    return str(x or "").strip()
def _fs_personal_sets(uid: str):
    return db.collection("flashcards").document(uid).collection("userFlashcards")
def _fs_community_sets():
    return db.collection("flashcard_sets")

_CARDID_COMPOSITE_RE = re.compile(
    r"^user_(?P<uid>.+?)(?:\:\:|:)set_(?P<setId>.+?)(?:\:\:|:)word_(?P<word>.+)$"
)

def _parse_composite_card_id(card_id: str) -> Optional[Dict[str, str]]:
    s = str(card_id or "").strip()
    if not s:
        return None

    m = _CARDID_COMPOSITE_RE.match(s)
    if not m:
        return None

    return {
        "uid": m.group("uid"),
        "setId": m.group("setId"),
        "word": m.group("word"),
    }


def _fs_build_due_matches(
    uid: str,
    wanted: set[str],
    *,
    include_community: bool = False,
) -> Dict[str, List[DueCardMatch]]:
    """
    Build matches by parsing composite cardId -> setId/word,
    fetch set doc by setId, then lookup word in vocabList.
    """
    result: Dict[str, List[DueCardMatch]] = {cid: [] for cid in wanted}

    if not USE_FIRESTORE or db is None or not wanted:
        return result

    def get_set_title(data: Dict[str, Any]) -> str:
        return str(
            data.get("title")
            or data.get("setTitle")
            or data.get("name")
            or "Untitled"
        )

    # Group wanted cardIds by setId to reduce reads
    grouped: Dict[str, List[tuple[str, str]]] = {}  # setId -> [(cardId, word)]
    for cid in wanted:
        meta = _parse_composite_card_id(cid)
        if not meta:
            continue

        # Ignore if embedded uid mismatches current uid
        if meta.get("uid") and meta["uid"] != uid:
            continue

        set_id = meta["setId"]
        word = meta["word"]
        grouped.setdefault(set_id, []).append((cid, word))

    for set_id, pairs in grouped.items():
        snap = None
        tab_name = "personal"

        # 1) Try personal set
        try:
            snap = _fs_personal_sets(uid).document(set_id).get()
        except Exception:
            snap = None

        # 2) Fallback to community set (optional)
        if (snap is None or not getattr(snap, "exists", False)) and include_community:
            tab_name = "community"
            try:
                snap = _fs_community_sets().document(set_id).get()
            except Exception:
                snap = None

        if snap is None or not getattr(snap, "exists", False):
            continue

        data = snap.to_dict() or {}
        set_title = get_set_title(data)
        set_source = data.get("source") if isinstance(data.get("source"), dict) else None

        vocab = _extract_vocab_list(data.get("vocabList"))
        vocab_index: Dict[str, Dict[str, Any]] = {}
        for v in vocab:
            w = _norm_card_key(v.get("word"))
            if w:
                vocab_index[w] = v

        for cid, w_raw in pairs:
            w_key = _norm_card_key(w_raw)
            v = vocab_index.get(w_key)

            if not v:
                # Still return set identity so FE can navigate to set
                result[cid].append(
                    DueCardMatch(
                        tab=tab_name,
                        setId=set_id,
                        setTitle=set_title,
                        setSource=set_source,
                        word=w_raw,
                        reading=None,
                        meaning=None,
                        imageUrl=None,
                    )
                )
                continue

            reading = v.get("romaji") or v.get("reading") or None

            result[cid].append(
                DueCardMatch(
                    tab=tab_name,
                    setId=set_id,
                    setTitle=set_title,
                    setSource=set_source,
                    word=w_key,
                    reading=reading,
                    meaning=v.get("meaning") or None,
                    imageUrl=v.get("imageUrl") or None,
                )
            )

    return result

@app.get("/stats/due_cards_detail", response_model=DueCardsDetailResponse)
def stats_due_cards_detail(
    scope: str = Query("now", description="now|today"),
    limit: int = Query(200, ge=1, le=500),
    tz_offset_min: int = Query(420, alias="tz_offset_min"),
    include_community: bool = Query(False, alias="includeCommunity"),
    uid: Optional[str] = Query(None, alias="uid"),  # NEW
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
) -> DueCardsDetailResponse:
    # if request is not None:
    #     print("due_cards_detail header x-user-id =", request.headers.get("x-user-id"))
    uid_val = _require_uid2(x_user_id, uid)  # dùng fallback
    registry = _get_registry(uid_val)
    # uid = _require_uid(x_user_id)
    # registry = _get_registry(uid)
  

    scope = (scope or "").strip().lower()
    if scope not in ("now", "today"):
        raise HTTPException(status_code=400, detail="scope must be now|today")

    tz_offset_min = int(tz_offset_min or 0)
    tz_offset_min = max(-720, min(tz_offset_min, 840))

    now_utc = datetime.now(timezone.utc)
    local_now = _shift_tz(now_utc, tz_offset_min)
    local_today = local_now.date()

    def _iso_utc_z(dt: datetime) -> str:
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        else:
            dt = dt.astimezone(timezone.utc)
        return dt.isoformat().replace("+00:00", "Z")

    picked: List[tuple[datetime, str, Any]] = []  # (due_local, cardId, card)

    for cid, card in registry.items():
        due_utc = _safe_due_utc(card)
        if due_utc is None:
            continue
        due_local = _shift_tz(due_utc, tz_offset_min)

        ok = (due_local <= local_now) if scope == "now" else (due_local.date() == local_today)
        if ok:
            picked.append((due_local, str(cid), card))

    picked.sort(key=lambda x: x[0])
    total = len(picked)
    picked = picked[:limit]

    wanted = {cid for _, cid, _ in picked}
    matches_map = _fs_build_due_matches(uid_val, wanted, include_community=bool(include_community))

    items: List[DueCardDetailItem] = []
    for _, cid, card in picked:
        due_utc = _safe_due_utc(card)
        items.append(
            DueCardDetailItem(
                cardId=cid,
                due=_iso_utc_z(due_utc) if due_utc else None,
                state=_safe_state_name(card),
                matches=matches_map.get(cid, []),
            )
        )

    return DueCardsDetailResponse(scope=scope, total=total, items=items)

# ============================================================
# 7) /stats/progress (lịch sử ôn tập + reviews per day)
# ============================================================

class DailyProgress(BaseModel):
    day: str              # YYYY-MM-DD (UTC)
    reviews: int
    good_easy: int
    xp: int
    success_rate: float   # good_easy / reviews (0..1)

class ReviewEvent(BaseModel):
    ts: str               # ISO UTC 'Z'
    cardId: str
    rating: int
    match: Optional[DueCardMatch] = None

class StatsProgressResponse(BaseModel):
    days: int
    daily: List[DailyProgress]
    recent: List[ReviewEvent]

def _iso_utc_z(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt.isoformat().replace("+00:00", "Z")

@app.get("/stats/progress", response_model=StatsProgressResponse)
def stats_progress(
    days: int = 14,
    recent: int = 20,
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
) -> StatsProgressResponse:
    uid = _require_uid(x_user_id)
    paths = _user_paths(uid)
    logs_path = paths["logs"]

    # clamp để tránh request quá nặng
    days = max(1, min(int(days), 60))
    recent = max(0, min(int(recent), 100))

    now = datetime.now(timezone.utc)
    today = now.date()
    start_day = today - timedelta(days=days - 1)

    # buckets theo ngày (UTC)
    bucket_dates = [start_day + timedelta(days=i) for i in range(days)]
    by_day: Dict[date, Dict[str, int]] = {
        d: {"reviews": 0, "good_easy": 0, "xp": 0} for d in bucket_dates
    }

    events: List[Dict[str, Any]] = []  # {ts_dt, ts_str, cardId, rating}

    def add_row(ts_dt: Optional[datetime], card_id: str, rating: int):
        if ts_dt is None:
            return
        if ts_dt.tzinfo is None:
            ts_dt = ts_dt.replace(tzinfo=timezone.utc)
        else:
            ts_dt = ts_dt.astimezone(timezone.utc)

        d = ts_dt.date()
        if d in by_day and rating in (1, 2, 3, 4):
            by_day[d]["reviews"] += 1
            by_day[d]["xp"] += _xp_for_rating(rating)
            if rating in (3, 4):
                by_day[d]["good_easy"] += 1

        events.append(
            {
                "ts_dt": ts_dt,
                "ts": _iso_utc_z(ts_dt),
                "cardId": str(card_id),
                "rating": int(rating),
            }
        )

    if USE_FIRESTORE:
        # MVP: stream toàn bộ rồi sort tại chỗ (đơn giản, ít rủi ro)
        for doc in _fs_reviews_col(uid).stream():
            row = doc.to_dict() or {}
            r = int(row.get("rating", 0))
            card_id = row.get("cardId") or row.get("card_id") or ""
            ts = row.get("ts")

            ts_dt: Optional[datetime] = None
            if hasattr(ts, "datetime"):
                ts_dt = ts.datetime.replace(tzinfo=timezone.utc)
            elif isinstance(ts, datetime):
                ts_dt = ts.astimezone(timezone.utc)
            elif isinstance(ts, str):
                ts_dt = _parse_ts({"ts": ts})

            add_row(ts_dt, str(card_id), r)

    else:
        if logs_path.exists():
            with logs_path.open("r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        row = json.loads(line)
                        r = int(row.get("rating", 0))
                        card_id = row.get("cardId") or row.get("card_id") or ""
                        ts_dt = _parse_ts(row)
                        add_row(ts_dt, str(card_id), r)
                    except Exception:
                        continue

    # recent events: sort desc theo ts_dt
    events.sort(key=lambda x: x["ts_dt"], reverse=True)
    picked = events[:recent]

    matches_map: Dict[str, List[DueCardMatch]] = {}
    if USE_FIRESTORE and picked:
        wanted = {e["cardId"] for e in picked if e.get("cardId")}
        matches_map = _fs_build_due_matches(uid, wanted, include_community=True)

    def pick_match(cid: str) -> Optional[DueCardMatch]:
        ms = matches_map.get(cid) or []
        return ms[0] if ms else None

    recent_events = [
        ReviewEvent(
            ts=e["ts"],
            cardId=e["cardId"],
            rating=e["rating"],
            match=pick_match(e["cardId"]),
        )
        for e in picked
    ]


    # daily output: sort asc theo ngày
    daily_out: List[DailyProgress] = []
    for d in bucket_dates:
        reviews = by_day[d]["reviews"]
        good_easy = by_day[d]["good_easy"]
        xp = by_day[d]["xp"]
        sr = (good_easy / reviews) if reviews > 0 else 0.0
        daily_out.append(
            DailyProgress(
                day=d.isoformat(),
                reviews=reviews,
                good_easy=good_easy,
                xp=xp,
                success_rate=sr,
            )
        )

    return StatsProgressResponse(days=days, daily=daily_out, recent=recent_events)

# ============================================================
# AI COACH (insights + coach chat)
# ============================================================

class CoachItem(BaseModel):
    title: str
    detail: str


class CoachAction(BaseModel):
    title: str
    detail: str
    cta: str
    action: str  # start_review_due_now | start_review_today | open_study_plan


class AiCoachResponse(BaseModel):
    strengths: List[CoachItem]
    improvements: List[CoachItem]
    today_action: CoachAction
    meta: Dict[str, Any] = {}


def _strip_code_fence(s: str) -> str:
    t = (s or "").strip()
    if t.startswith("```"):
        t = t.strip().strip("`").strip()
        if t.lower().startswith("json"):
            t = t[4:].strip()
    return t


def _uid_or_default(x_user_id: Optional[str]) -> str:
    # dev-friendly: không có header thì dùng local
    u = (x_user_id or "").strip()
    return u if u else "local"


def _read_rating_count(by_rating: Any, key: int) -> int:
    if not by_rating:
        return 0
    # backend có thể trả key int hoặc str
    if isinstance(by_rating, dict):
        v = by_rating.get(key)
        if v is None:
            v = by_rating.get(str(key))
        try:
            return int(v or 0)
        except Exception:
            return 0
    return 0


def _coach_fallback_from_stats(s: Any) -> AiCoachResponse:
    due_now = int(getattr(s, "due_now", 0) or 0)
    due_today = int(getattr(s, "due_today", 0) or 0)
    streak_current = int(getattr(s, "streak_current", 0) or 0)
    reviews_last_7d = int(getattr(s, "reviews_last_7d", 0) or 0)
    sr7 = float(getattr(s, "success_rate_7d", 0.0) or 0.0)
    sra = float(getattr(s, "success_rate_all_time", 0.0) or 0.0)

    by_rating = getattr(s, "reviews_by_rating", None) or {}
    again = _read_rating_count(by_rating, 1)
    hard = _read_rating_count(by_rating, 2)
    good = _read_rating_count(by_rating, 3)
    easy = _read_rating_count(by_rating, 4)

    # Strengths
    strengths: List[CoachItem] = []
    if reviews_last_7d <= 0:
        strengths.append(CoachItem(title="Điểm mạnh", detail="Chưa đủ dữ liệu 7 ngày để kết luận điểm mạnh."))
    else:
        sr7_pct = int(round(sr7 * 100))
        strengths.append(CoachItem(title="Điểm mạnh", detail=f"Tỉ lệ thành công 7 ngày: {sr7_pct}% (Good+Easy chiếm đa số nếu duy trì đều)."))
        if (good + easy) > (again + hard):
            strengths.append(CoachItem(title="Điểm mạnh", detail="Nhịp ôn hiện tại đang nghiêng về Good/Easy, độ nhớ đang ổn định."))

    # Improvements
    improvements: List[CoachItem] = []
    if due_now > 0:
        improvements.append(CoachItem(title="Cần cải thiện", detail=f"Có {due_now} thẻ quá hạn. Ưu tiên xử lý quá hạn trước để giảm dồn lịch."))
    else:
        improvements.append(CoachItem(title="Cần cải thiện", detail="Không có dấu hiệu quá hạn lớn. Duy trì ôn đều để tránh dồn lịch."))

    if reviews_last_7d > 0:
        if (again + hard) >= (good + easy):
            improvements.append(CoachItem(title="Cần cải thiện", detail="Tỉ lệ Again/Hard đang cao. Giảm tốc độ học mới, tăng ôn củng cố nhóm khó."))

    # Today action
    if due_now > 0:
        take = min(15, due_now)
        today_action = CoachAction(
            title="Gợi ý hành động hôm nay",
            detail=f"Ôn {take} thẻ quá hạn trước, sau đó hoàn thành phần đến hạn trong hôm nay ({due_today}).",
            cta="Thực hiện",
            action="start_review_due_now",
        )
    elif due_today > 0:
        today_action = CoachAction(
            title="Gợi ý hành động hôm nay",
            detail=f"Hoàn thành {due_today} thẻ đến hạn để giữ nhịp ôn.",
            cta="Thực hiện",
            action="start_review_today",
        )
    else:
        today_action = CoachAction(
            title="Gợi ý hành động hôm nay",
            detail="Không có thẻ đến hạn. Có thể học mới 5–10 thẻ hoặc ôn lại nhóm Hard.",
            cta="Mở kế hoạch",
            action="open_study_plan",
        )

    return AiCoachResponse(
        strengths=strengths[:2] if strengths else [CoachItem(title="Điểm mạnh", detail="—")],
        improvements=improvements[:2] if improvements else [CoachItem(title="Cần cải thiện", detail="—")],
        today_action=today_action,
        meta={
            "streak_current": streak_current,
            "due_now": due_now,
            "due_today": due_today,
            "reviews_last_7d": reviews_last_7d,
            "success_rate_7d": sr7,
            "success_rate_all_time": sra,
            "ratings": {"again": again, "hard": hard, "good": good, "easy": easy},
        },
    )
def _json_safe(x: Any) -> Any:
    if x is None:
        return None
    if isinstance(x, (str, int, float, bool)):
        return x
    if isinstance(x, datetime):
        return _iso_utc_z(x)
    if isinstance(x, list):
        return [_json_safe(i) for i in x]
    if isinstance(x, dict):
        return {str(k): _json_safe(v) for k, v in x.items()}
    return str(x)
def _coach_sample_due(uid: str, tz_offset_min: int, limit_each: int = 3) -> Dict[str, Any]:
    registry = _get_registry(uid)
    now_utc = datetime.now(timezone.utc)
    local_now = _shift_tz(now_utc, tz_offset_min)
    local_today = local_now.date()

    due_now_list: List[tuple[datetime, str, Any]] = []
    due_today_list: List[tuple[datetime, str, Any]] = []

    for cid, card in registry.items():
        due_utc = _safe_due_utc(card)
        if due_utc is None:
            continue
        due_local = _shift_tz(due_utc, tz_offset_min)

        if due_local <= local_now:
            due_now_list.append((due_local, str(cid), card))
        if due_local.date() == local_today:
            due_today_list.append((due_local, str(cid), card))

    due_now_list.sort(key=lambda x: x[0])
    due_today_list.sort(key=lambda x: x[0])

    pick_now = due_now_list[:limit_each]
    pick_today = due_today_list[:limit_each]

    wanted = {cid for _, cid, _ in (pick_now + pick_today)}
    matches_map = _fs_build_due_matches(uid, wanted, include_community=True)

    def pack(rows: List[tuple[datetime, str, Any]]) -> List[Dict[str, Any]]:
        out: List[Dict[str, Any]] = []
        for dlocal, cid, card in rows:
            ms = matches_map.get(cid) or []
            m0 = ms[0].dict() if ms else None
            out.append(
                {
                    "cardId": cid,
                    "dueLocal": dlocal.strftime("%Y-%m-%d %H:%M"),
                    "state": _safe_state_name(card),
                    "match": _json_safe(m0) if m0 else None,
                }
            )
        return out

    return {
        "due_now_samples": pack(pick_now),
        "due_today_samples": pack(pick_today),
    }

def _build_coach_insights(
    *,
    uid: str,
    s: StatsSummaryResponse,
    horizon_days: int,
    tz_offset_min: int,
) -> Dict[str, Any]:
    now_utc = datetime.now(timezone.utc)
    events = _load_review_events(uid, tz_offset_min)

    # ---- windows ----
    cutoff_7d = now_utc - timedelta(days=7)
    cutoff_14d = now_utc - timedelta(days=14)
    cutoff_30d = now_utc - timedelta(days=30)

    e7 = [e for e in events if e["ts_utc"] >= cutoff_7d]
    e14 = [e for e in events if e["ts_utc"] >= cutoff_14d]
    e30 = [e for e in events if e["ts_utc"] >= cutoff_30d]

    # ---- Habit: hour profile (local) ----
    hour = {h: {"n": 0, "ah": 0} for h in range(24)}  # ah = again+hard
    for e in e14:
        h = int(e["ts_local"].hour)
        hour[h]["n"] += 1
        if e["rating"] in (1, 2):
            hour[h]["ah"] += 1

    peak_hour = None
    peak_rate = 0.0
    for h in range(24):
        n = hour[h]["n"]
        if n >= 10:
            rate = hour[h]["ah"] / max(1, n)
            if rate > peak_rate:
                peak_rate = rate
                peak_hour = h

    habit_insights: List[Dict[str, Any]] = []
    if peak_hour is not None and peak_rate >= 0.45:
        if peak_hour >= 22 or peak_hour <= 6:
            habit_insights.append(
                {
                    "type": "hour_fatigue",
                    "pattern": f"Lượt Again/Hard tăng mạnh vào khoảng {peak_hour:02d}:00.",
                    "why": "Cuối ngày hoặc quá sớm dễ mệt, khả năng nhớ giảm.",
                    "experiment": "Dời phiên ôn chính sang 18–21h; giữ phiên khuya chỉ 5 phút ôn nhanh.",
                    "evidence": {"peakHour": peak_hour, "againHardRate": round(peak_rate, 3)},
                }
            )
        else:
            habit_insights.append(
                {
                    "type": "hour_peak",
                    "pattern": f"Khung {peak_hour:02d}:00 có tỷ lệ Again/Hard cao hơn hẳn.",
                    "why": "Có thể trùng lúc thiếu tập trung hoặc học vội.",
                    "experiment": "Đổi thứ tự: thẻ khó trước, thẻ mới sau; giảm tốc độ trong 10 phút đầu.",
                    "evidence": {"peakHour": peak_hour, "againHardRate": round(peak_rate, 3)},
                }
            )

    # ---- Habit: weekday gaps (local dates) ----
    daily_counts: Dict[date, int] = {}
    for e in e14:
        d = e["ts_local"].date()
        daily_counts[d] = daily_counts.get(d, 0) + 1

    # thống kê theo thứ (0=Mon..6=Sun)
    wd = {i: 0 for i in range(7)}
    for d, n in daily_counts.items():
        wd[d.weekday()] += n

    # tìm 1-2 thứ yếu nhất nhưng phải có dữ liệu >= 7 ngày
    if len(daily_counts) >= 7:
        weakest = sorted(wd.items(), key=lambda x: x[1])[:2]
        w0, w1 = weakest[0][0], weakest[1][0]
        habit_insights.append(
            {
                "type": "weekday_gap",
                "pattern": "Có dấu hiệu hay nghỉ/ít ôn vào một số ngày cố định trong tuần.",
                "why": "Khi bỏ trống 1–2 ngày, lịch due dễ tạo “đỉnh” 2–3 ngày sau.",
                "experiment": "Đặt ‘phiên mini 5 phút’ vào ngày hay bỏ trống, chỉ làm 5–7 thẻ.",
                "evidence": {"weakWeekdays": [w0, w1], "weekdayCounts": wd},
            }
        )

    # ---- Unevenness: dồn 1-2 ngày ----
    if daily_counts:
        counts = list(daily_counts.values())
        avg = sum(counts) / max(1, len(counts))
        mx = max(counts)
        if avg > 0 and mx >= avg * 2.5:
            habit_insights.append(
                {
                    "type": "batching",
                    "pattern": "Nhịp ôn không đều: có ngày ôn dồn nhiều, rồi nghỉ dài.",
                    "why": "FSRS sẽ đẩy lịch due tập trung vào 1–3 ngày sau đó, gây quá tải.",
                    "experiment": "Chia đều 2 phiên/ngày (7–10 phút), ưu tiên đều đặn hơn số lượng.",
                    "evidence": {"maxPerDay": mx, "avgPerDay": round(avg, 2)},
                }
            )

    # ---- Error profile (7d) ----
    by_rating_7d = {"1": 0, "2": 0, "3": 0, "4": 0}
    for e in e7:
        by_rating_7d[str(e["rating"])] += 1
    total7 = sum(by_rating_7d.values())
    again = by_rating_7d["1"]
    hard = by_rating_7d["2"]
    good = by_rating_7d["3"]
    easy = by_rating_7d["4"]

    error_profile: List[Dict[str, Any]] = []
    if total7 >= 10:
        ah = (again + hard) / max(1, total7)
        ge = (good + easy) / max(1, total7)
        if ah >= 0.45:
            error_profile.append(
                {
                    "type": "high_ah",
                    "pattern": "Tỷ lệ Again/Hard chiếm phần lớn trong 7 ngày gần đây.",
                    "why": "Dấu hiệu nhớ lơ mơ hoặc học khi mệt; học mới lúc này dễ làm backlog tăng.",
                    "experiment": "Giảm học mới 1–2 ngày; ưu tiên ôn nhóm Hard/Again gần nhất.",
                    "evidence": {"againHardShare": round(ah, 3), "goodEasyShare": round(ge, 3)},
                }
            )
        if good > 0 and easy == 0:
            error_profile.append(
                {
                    "type": "good_not_easy",
                    "pattern": "Good xuất hiện nhiều nhưng Easy rất ít.",
                    "why": "Nhớ đủ để qua bài nhưng chưa chắc; dễ tái sai khi đổi ngữ cảnh.",
                    "experiment": "Cuối phiên thêm 3 phút ‘ôn nhanh’: chỉ làm lại thẻ Good vừa xong.",
                    "evidence": {"good": good, "easy": easy},
                }
            )
        if again >= max(3, int(0.2 * total7)):
            error_profile.append(
                {
                    "type": "again_spike",
                    "pattern": "Again xuất hiện khá thường xuyên trong 7 ngày.",
                    "why": "Có thể do phiên ôn dài hoặc tốc độ quá nhanh.",
                    "experiment": "Thử ‘phiên 10 phút – mục tiêu 0 Again’: chậm lại, đọc kỹ mặt sau.",
                    "evidence": {"again": again, "total7": total7},
                }
            )

    # ---- Workload shaping: peak due from stats_summary buckets ----
    workload_insights: List[Dict[str, Any]] = []
    due_buckets = getattr(s, "due_next_7d", []) or []
    if due_buckets:
        counts = [int(b.count) for b in due_buckets]
        avg = sum(counts) / max(1, len(counts))
        mx = max(counts)
        mx_idx = counts.index(mx)
        peak_day = due_buckets[mx_idx].day
        if avg > 0 and mx >= avg * 1.8 and mx >= 10:
            workload_insights.append(
                {
                    "type": "due_peak",
                    "pattern": f"Sắp có “đỉnh” lịch đến hạn quanh {peak_day}.",
                    "why": "Khi ôn dồn/nghỉ, due sẽ gom cụm vài ngày sau.",
                    "experiment": "Chia 2 phiên/ngày trong 48h tới để hạ đỉnh (7–10 phút mỗi phiên).",
                    "evidence": {"peakDay": peak_day, "peakCount": mx, "avg": round(avg, 2)},
                }
            )

    # ---- Top hard cards (30d) ----
    by_card_again: Dict[str, int] = {}
    by_card_last: Dict[str, datetime] = {}
    for e in e30:
        cid = e["cardId"]
        ts = e["ts_utc"]
        if cid and (cid not in by_card_last or ts > by_card_last[cid]):
            by_card_last[cid] = ts
        if e["rating"] == 1:
            by_card_again[cid] = by_card_again.get(cid, 0) + 1

    top_hard = sorted(by_card_again.items(), key=lambda x: x[1], reverse=True)[:5]
    top_hard_cards = [
        {
            "cardId": cid,
            "againCount30d": n,
            "lastSeen": _iso_utc_z(by_card_last.get(cid)) if cid in by_card_last else None,
        }
        for cid, n in top_hard
        if cid
    ]

    # ---- Challenges (3) ----
    challenges: List[Dict[str, Any]] = []
    # Challenge 1: xử lý Again gần nhất
    if top_hard_cards:
        challenges.append(
            {
                "title": "Thử thách 1",
                "detail": "Xử lý 5 thẻ hay Again gần đây trước khi học mới.",
                "cta": "Chấp nhận thử thách",
                "action": "review_top_hard_5",
            }
        )
    # Challenge 2: phiên 10 phút 0 Again
    challenges.append(
        {
            "title": "Thử thách 2",
            "detail": "Phiên 10 phút – mục tiêu 0 Again (chậm lại, đọc kỹ).",
            "cta": "Bắt đầu phiên 10 phút",
            "action": "start_focus_10m",
        }
    )
    # Challenge 3: chia 2 phiên
    challenges.append(
        {
            "title": "Thử thách 3",
            "detail": "Chia 2 phiên sáng/tối, mỗi phiên 7–10 phút để ổn định nhịp.",
            "cta": "Lên lịch 2 phiên",
            "action": "split_sessions",
        }
    )

    # ---- Plan 7 days (chiến lược) ----
    plan_7d = [
        {"day": 1, "goal": "Giảm dồn lịch", "action": "Ưu tiên thẻ khó trước, giữ phiên ngắn."},
        {"day": 2, "goal": "Giảm dồn lịch", "action": "Chia 2 phiên/ngày để hạ ‘đỉnh’ due."},
        {"day": 3, "goal": "Ổn định nhịp", "action": "Giữ 1 khung giờ cố định, mini 5 phút nếu bận."},
        {"day": 4, "goal": "Ổn định nhịp", "action": "Giảm học mới nếu Again/Hard còn cao."},
        {"day": 5, "goal": "Tăng chất lượng", "action": "Thêm 3 phút ôn nhanh cuối phiên cho thẻ Good."},
        {"day": 6, "goal": "Tăng chất lượng", "action": "Ôn nhóm khó 5 thẻ, chú ý ví dụ/ngữ cảnh."},
        {"day": 7, "goal": "Giữ nhịp dài hạn", "action": "Tổng kết: chọn 1 thói quen cố định cho tuần sau."},
    ]
    review_ctx = _coach_sample_due(uid, tz_offset_min, limit_each=3)

    top_ids = {x.get("cardId") for x in top_hard_cards if x.get("cardId")}
    matches_top = _fs_build_due_matches(uid, set([i for i in top_ids if i]), include_community=True)

    top_hard_cards_enriched: List[Dict[str, Any]] = []
    for x in top_hard_cards:
        cid = x.get("cardId")
        ms = matches_top.get(cid) or []
        m0 = ms[0].dict() if ms else None
        top_hard_cards_enriched.append({**x, "match": _json_safe(m0) if m0 else None})


    return {
        "habit_insights": habit_insights[:3],
        "workload_insights": workload_insights[:2],
        "error_profile": error_profile[:3],
        "challenges": challenges,
        "top_hard_cards": top_hard_cards_enriched,
        "review_context": review_ctx,
        "plan_7d": plan_7d,
        "by_rating_7d": by_rating_7d,
    }


@app.get("/ai/learning/coach", response_model=AiCoachResponse)
def ai_learning_coach(
    horizon_days: int = Query(7, alias="horizonDays"),
    tz_offset_min: int = Query(0, alias="tzOffsetMin"),
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
) -> AiCoachResponse:
    """
    AI Coach trả về dữ liệu cho card 'Gợi ý từ AI (hôm nay)' trong Statistics.
    Reuse stats_summary (đã chốt) để lấy metric cá nhân hoá.
    """
    uid = _uid_or_default(x_user_id)

    s = stats_summary(  # noqa: F821
        horizon_days=horizon_days,
        tz_offset_min=tz_offset_min,
        x_user_id=uid,
    )

    # ---- Build insights (nguồn chính) ----
    try:
        ins = _build_coach_insights(
            uid=uid,
            s=s,
            horizon_days=horizon_days,
            tz_offset_min=tz_offset_min,
        )
    except Exception:
        # Nếu insight lỗi (thiếu logs, lỗi parse...), fallback cũ để không crash UI
        return _coach_fallback_from_stats(s)

    # ---- Base response (không cần Gemini) ----
    strengths: List[CoachItem] = []
    improvements: List[CoachItem] = []

    # Strengths: ưu tiên nói điều user không nhìn thấy ngay
    # (giữ câu trung tính, không nhắc % hoặc số due)
    if int(getattr(s, "streak_current", 0) or 0) > 0:
        strengths.append(
            CoachItem(
                title="Nhịp học",
                detail="Đang có dấu hiệu duy trì nhịp ôn liên tục. Nhịp đều giúp lịch ôn mượt hơn và giảm dồn thẻ.",
            )
        )
    else:
        strengths.append(
            CoachItem(
                title="Nền dữ liệu",
                detail="Đã có dữ liệu ôn tập để phát hiện thói quen và nhóm thẻ khó. Tối ưu nhịp học sẽ cải thiện nhanh.",
            )
        )

    # Improvements: lấy từ insight theo thứ tự ưu tiên
    habit_list = ins.get("habit_insights") or []
    workload_list = ins.get("workload_insights") or []
    error_list = ins.get("error_profile") or []

    if habit_list:
        x = habit_list[0]
        improvements.append(
            CoachItem(
                title="Thói quen học",
                detail=f'{x.get("pattern","")} {x.get("why","")} Thử: {x.get("experiment","")}',
            )
        )

    if workload_list:
        x = workload_list[0]
        improvements.append(
            CoachItem(
                title="Dồn lịch",
                detail=f'{x.get("pattern","")} {x.get("why","")} Thử: {x.get("experiment","")}',
            )
        )

    if len(improvements) < 2 and error_list:
        x = error_list[0]
        improvements.append(
            CoachItem(
                title="Hồ sơ lỗi sai",
                detail=f'{x.get("pattern","")} {x.get("why","")} Thử: {x.get("experiment","")}',
            )
        )

    strengths = strengths[:2] if strengths else [CoachItem(title="Điểm mạnh", detail="—")]
    improvements = improvements[:2] if improvements else [
        CoachItem(title="Cần cải thiện", detail="Chưa đủ dữ liệu để kết luận. Ôn thêm vài lượt để hệ thống nhận ra pattern.")
    ]

    # Today action: giữ action enum cũ để Flutter không vỡ
    due_now = int(getattr(s, "due_now", 0) or 0)
    due_today = int(getattr(s, "due_today", 0) or 0)

    if due_now > 0:
        today_action = CoachAction(
            title="Thử thách hôm nay",
            detail="Ưu tiên xử lý nhóm quá hạn trước, sau đó mới sang phần còn lại. Chia 2 phiên ngắn nếu mệt.",
            cta="Chấp nhận thử thách",
            action="start_review_due_now",
        )
    elif due_today > 0:
        today_action = CoachAction(
            title="Thử thách hôm nay",
            detail="Hoàn thành một phiên ngắn cho nhóm đến hạn để giữ nhịp, ưu tiên thẻ khó trước.",
            cta="Chấp nhận thử thách",
            action="start_review_today",
        )
    else:
        today_action = CoachAction(
            title="Thử thách hôm nay",
            detail="Không có thẻ đến hạn. Có thể làm phiên 10 phút ôn nhóm Hard/Again gần đây để tăng độ chắc.",
            cta="Mở kế hoạch",
            action="open_study_plan",
        )

    base = AiCoachResponse(
        strengths=strengths,
        improvements=improvements,
        today_action=today_action,
        meta={
            **(_coach_fallback_from_stats(s).meta or {}),
            **(ins or {}),
            "horizon_days": horizon_days,
            "tz_offset_min": tz_offset_min,
        },
    )

    # Không có Gemini => trả base
    if "gemini_model" not in globals() or globals().get("gemini_model") is None:
        return base

    # Có Gemini => chỉ “viết lại” dựa trên insight, không lặp %/số due
    prompt = f"""
Chỉ trả JSON theo schema:
{{
  "strengths":[{{"title":"...", "detail":"..."}}],
  "improvements":[{{"title":"...", "detail":"..."}}],
  "today_action":{{"title":"...", "detail":"...", "cta":"...", "action":"start_review_due_now|start_review_today|open_study_plan"}},
  "meta":{{}}
}}

Giọng điệu:
- Thân thiện, “nhí nhảnh” nhẹ kiểu 🐿️ (1–2 emoji là đủ).
- Ưu tiên ngôn ngữ học tập, tránh thuật ngữ kỹ thuật.

Quy tắc nội dung:
- Không liệt kê lại số liệu UI (%, số thẻ) một cách trần trụi.
- Có thể nhắc tối đa 1 con số nếu đi kèm nhận xét/ý nghĩa.
- Không dùng Markdown (**bold**, ###, ...).
- Mỗi insight nên có: nhận xét -> vì sao -> thử ngay (đo được).
- Chỉ dùng dữ liệu từ Insight, không bịa thêm.
- Nếu Insight thiếu dữ liệu (ít log / thiếu pattern), hãy nói ngắn gọn “chưa đủ dữ liệu” và đưa 1 gợi ý thử ngay.

Ngữ cảnh thẻ/bộ (nếu có trong Insight):
- Nếu có "review_context" hoặc "top_hard_cards" có "match": được phép nêu tối đa 2 ví dụ cụ thể theo mẫu:
  "Từ – Bộ – Nghĩa ngắn".
- Tuyệt đối không bịa tên bộ/bài; chỉ dùng đúng dữ liệu match nếu có.

Từ vựng thay thế:
- due/backlog/FSRS -> lịch ôn / dồn thẻ
- Again/Hard -> Quên (Again) / Khó (Hard) (chỉ nhắc khi cần)

Insight:
{json.dumps(ins, ensure_ascii=False)}
""".strip()

    try:
        result = globals()["gemini_model"].generate_content(prompt)
        raw = (result.text or "").strip() if result else ""
        raw = _strip_code_fence(raw)
        data = json.loads(raw)

        strengths_llm = [CoachItem(**x) for x in (data.get("strengths") or [])][:2]
        improvements_llm = [CoachItem(**x) for x in (data.get("improvements") or [])][:2]
        today_action_llm = CoachAction(**(data.get("today_action") or {}))
        today_action_llm = CoachAction(
            title=(today_action_llm.title or base.today_action.title),
            detail=(today_action_llm.detail or base.today_action.detail),
            cta=forced_cta,
            action=forced_action,
    )


        if not strengths_llm or not improvements_llm or not getattr(today_action_llm, "action", ""):
            return base

        return AiCoachResponse(
            strengths=strengths_llm,
            improvements=improvements_llm,
            today_action=today_action_llm,
            meta={**(base.meta or {}), **(data.get("meta") or {})},
        )
    except Exception:
        return base

class CoachChatRequest(BaseModel):
    question: str
    horizon_days: int = 7
    tz_offset_min: int = 0

class CoachChatResponse(BaseModel):
    answer: str


_MD_BOLD_RE = re.compile(r"\*\*(.+?)\*\*")
_MD_HEADER_RE = re.compile(r"^\s*#{1,6}\s*", re.MULTILINE)

def _sanitize_coach_text(s: str) -> str:
    t = (s or "").strip()
    if not t:
        return ""

    # Remove markdown bold + headers
    t = _MD_BOLD_RE.sub(r"\1", t)
    t = _MD_HEADER_RE.sub("", t)

    # Normalize common labels if model insists
    t = t.replace("Pattern:", "Nhận xét:")
    t = t.replace("Vì sao:", "Vì sao:")
    t = t.replace("Thử nghiệm cụ thể:", "Thử ngay:")
    t = t.replace("Thử nghiệm:", "Thử ngay:")

    # Remove stray code fences (rare)
    t = _strip_code_fence(t)

    # Trim excessive blank lines
    t = re.sub(r"\n{3,}", "\n\n", t).strip()
    return t

def _coach_chat_rule_based(question: str, ins: Dict[str, Any]) -> str:
    q_raw = (question or "").strip()
    q = q_raw.lower()

    ctx = ins.get("_ctx") or ins.get("_stats") or {}
    due_now = int(ctx.get("due_now") or 0)
    due_today = int(ctx.get("due_today") or 0)

    by7 = ins.get("by_rating_7d") or {"1": 0, "2": 0, "3": 0, "4": 0}
    total7 = int(sum(int(v or 0) for v in by7.values()))
    ah7 = int(by7.get("1", 0) or 0) + int(by7.get("2", 0) or 0)

    # 0) greeting / thanks
    if q in ("hi", "hello", "hey", "chào", "chao", "xin chào"):
        return (
            "🐿️ Sóc Lingua đây! Muốn bắt đầu nhẹ nhàng hay “đập dồn lịch” luôn?\n"
            "Gợi ý hỏi nhanh:\n"
            "• Hôm nay nên ôn gì?\n"
            "• Khung giờ nào dễ sai?\n"
            "• Vì sao hay Quên/Khó?\n"
            "• Có bị dồn lịch không?"
        )
    if not q_raw or len(q_raw) < 2 or q in ("?", "…", "..."):
        return (
            "🐿️ Muốn hỏi theo hướng nào nè?\n"
            "1) Hôm nay nên ôn gì?\n"
            "2) Khung giờ nào dễ sai?"
        )

    # 0.6) off-topic guard (không liên quan ôn tập/thống kê)
    study_keywords = (
        "ôn", "học", "hoc", "thẻ", "the", "flashcard", "lịch", "kế hoạch",
        "đến hạn", "qua han", "quá hạn", "due", "streak", "xp",
        "quên", "khó", "again", "hard", "good", "easy",
        "từ", "từ vựng", "vocab", "7 ngày", "28", "heatmap", "thống kê",
    )
    if not any(k in q for k in study_keywords):
        return (
            "🐿️ Coach này tập trung vào ôn tập & thống kê nên câu này hơi lệch chủ đề.\n"
            "Nếu muốn hỏi ngoài phạm vi này, dùng AI Learning Assistant nhé.\n"
            "Còn nếu muốn tối ưu ôn tập, thử hỏi:\n"
            "• Hôm nay nên ôn gì?\n"
            "• Có bị dồn lịch không?"
        )

    if "cảm ơn" in q or "cam on" in q or "thanks" in q or "thx" in q:
        return "🐿️ Không có gì nè! Muốn Sóc Lingua gợi ý bước tiếp theo không? Ví dụ: “Hôm nay nên ôn gì?”"

    # 1) hỏi kiểu “nên ôn gì / bắt đầu sao”
    if (
        "ôn gì" in q
        or "nên ôn" in q
        or "nên học" in q
        or "bắt đầu" in q
        or "làm gì" in q
        or "hôm nay" in q
    ):
        top = ins.get("top_hard_cards") or []
        lines = ["🐿️ Gợi ý lộ trình 7–10 phút, làm phát là vào nhịp luôn:"]

        if due_now > 0:
            lines.append("• Bước 1: xử lý vài thẻ đang bị trễ trước để lịch học bớt dồn.")
        if top:
            lines.append("• Bước 2: làm 5 thẻ hay “Quên” gần đây (thẻ khó trước, thẻ mới sau).")
        else:
            lines.append("• Bước 2: chọn 5 thẻ thấy “lăn tăn” nhất, làm chậm lại và đọc kỹ ví dụ/ngữ cảnh.")

        if due_today > 0:
            lines.append("• Bước 3: chốt thêm một nhóm thẻ đến hạn hôm nay để giữ nhịp.")

        if total7 >= 10:
            share = ah7 / max(1, total7)
            if share >= 0.45:
                lines.append("✨ Nhận xét: dạo này “Khó/Quên” xuất hiện hơi nhiều → ưu tiên ôn củng cố trước khi học mới sẽ lên nhanh hơn.")

        lines.append("🚀 Tip nhỏ: 2 phiên ngắn thường hiệu quả hơn 1 phiên dài.")
        return "\n".join(lines)

    # 2) thói quen / giờ
    if "thói quen" in q or "giờ" in q or "khi nào" in q:
        hi = (ins.get("habit_insights") or [])
        if hi:
            x = hi[0]
            return (
                "🐿️ Sóc Lingua thấy một dấu hiệu thú vị:\n"
                f"{x.get('pattern','')}\n"
                f"Vì sao có thể xảy ra: {x.get('why','')}\n"
                f"Thử ngay: {x.get('experiment','')}"
            )
        return "🐿️ Chưa đủ dữ liệu để kết luận thói quen theo giờ. Ôn thêm vài phiên rồi hỏi lại: “Khung giờ nào dễ sai nhất?”"

    # 3) dồn lịch / quá tải
    if "dồn" in q or "quá tải" in q or "đỉnh" in q or "backlog" in q:
        wi = (ins.get("workload_insights") or [])
        if wi:
            x = wi[0]
            return (
                "🐿️ Có dấu hiệu lịch ôn bị gom cụm:\n"
                f"{x.get('pattern','')}\n"
                f"Vì sao: {x.get('why','')}\n"
                f"Thử ngay: {x.get('experiment','')}"
            )
        return "🐿️ Chưa thấy “đỉnh” rõ rệt. Nếu muốn phòng ngừa: chia 2 phiên 7–10 phút/ngày sẽ giữ nhịp ổn định."

    # 4) hay sai / quên / khó
    if "sai" in q or "quên" in q or "khó" in q or "again" in q or "hard" in q:
        ep = (ins.get("error_profile") or [])
        if ep:
            x = ep[0]
            return (
                "🐿️ Kiểu vấp phổ biến gần đây là:\n"
                f"{x.get('pattern','')}\n"
                f"Vì sao: {x.get('why','')}\n"
                f"Thử ngay: {x.get('experiment','')}"
            )
        return "🐿️ Chưa đủ dữ liệu để tách kiểu sai. Ôn thêm vài phiên rồi hỏi: “Vì sao hay Quên?” để soi rõ hơn."

    # 5) top thẻ khó
    if "thẻ khó" in q or "top" in q:
        top = ins.get("top_hard_cards") or []
        if not top:
            return "🐿️ Chưa có thẻ nào nổi bật về “Quên” trong 30 ngày gần đây."
        lines = ["🐿️ Top thẻ hay “Quên” (ưu tiên xử lý trước):"]
        for i, it in enumerate(top[:5], start=1):
            lines.append(f"• {i}) {it.get('cardId','')}")
        lines.append("🎯 Tip: chậm lại ở 3 thẻ đầu để “kéo chất lượng” lên.")
        return "\n".join(lines)

    # 6) kế hoạch 7 ngày
    if "kế hoạch" in q or "7 ngày" in q:
        plan = ins.get("plan_7d") or []
        if not plan:
            return "🐿️ Chưa đủ dữ liệu để lập kế hoạch 7 ngày."
        lines = ["🐿️ Kế hoạch 7 ngày (ngắn gọn, dễ theo):"]
        for p in plan:
            lines.append(f"• Ngày {p.get('day')}: {p.get('goal')} — {p.get('action')}")
        return "\n".join(lines)

    # default
    return (
        "🐿️ Sóc Lingua chưa bắt được ý câu này. Thử một câu hỏi gần giống nè:\n"
        "• Hôm nay nên ôn gì?\n"
        "• Khung giờ nào dễ sai?\n"
        "• Vì sao hay Quên/Khó?\n"
        "• Có bị dồn lịch không?\n"
        "• Lập kế hoạch 7 ngày"
    )


@app.post("/ai/coach/chat", response_model=CoachChatResponse)
def ai_coach_chat(
    req: CoachChatRequest,
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
) -> CoachChatResponse:
    uid = _require_uid(x_user_id)
    s = stats_summary(
        horizon_days=req.horizon_days,
        tz_offset_min=req.tz_offset_min,
        x_user_id=uid,
    )

    ins_raw = _build_coach_insights(
        uid=uid,
        s=s,
        horizon_days=req.horizon_days,
        tz_offset_min=req.tz_offset_min,
    )

    ins = {
        **(ins_raw or {}),
        "_ctx": {
            "due_now": int(getattr(s, "due_now", 0) or 0),
            "due_today": int(getattr(s, "due_today", 0) or 0),
            "streak_current": int(getattr(s, "streak_current", 0) or 0),
            "reviews_last_7d": int(getattr(s, "reviews_last_7d", 0) or 0),
            "success_rate_7d": float(getattr(s, "success_rate_7d", 0.0) or 0.0),
            "success_rate_all_time": float(getattr(s, "success_rate_all_time", 0.0) or 0.0),
        },
    }


    if gemini_model is None:
        return CoachChatResponse(answer=_coach_chat_rule_based(req.question, ins))

    prompt = (
    "Vai trò: Lingua Coach 🐿️ (giọng vui vẻ, dễ hiểu).\n"
    "Mục tiêu: đưa nhận xét hữu ích từ Insight + gợi ý thử ngay.\n"
    "Yêu cầu:\n"
    "- Plain text, tuyệt đối không dùng Markdown (không **, không ###).\n"
    "- Tránh lặp số liệu UI; nếu nhắc số thì 1 hoặc 2 con số và kèm nhận xét.\n"
    "- Viết tự nhiên như nói chuyện, không dùng tiêu đề kiểu “Pattern/Vì sao”.\n"
    "- Nếu người dùng chỉ chào/ cảm ơn: trả lời ngắn + gợi ý 1 câu hỏi tiếp theo.\n\n"
    "-Nếu câu hỏi mơ hồ: hỏi lại 1 câu để làm rõ, kèm 2 lựa chọn.\n\n"
    "- Nếu câu hỏi KHÔNG liên quan ôn tập/thống kê: trả lời 1 câu ngắn nói Coach chỉ tập trung ôn tập, "
    "gợi ý dùng AI Learning Assistant cho câu hỏi đó, và đề xuất 2 câu hỏi đúng chủ đề.\n"
    "- Nếu câu hỏi quá mơ hồ/rỗng: hỏi lại 1 câu để làm rõ, kèm 2 lựa chọn.\n\n"
    "Ví dụ giọng văn mong muốn (minh hoạ, không gán cứng thời điểm; phải bám Insight):\n"
    "“🐿️ Có vẻ có một khung giờ trong ngày dễ vấp hơn một chút. Khi ôn lúc mệt hoặc thiếu tập trung, dễ làm nhanh nên độ nhớ không chắc.\n"
    "Thử ngay: 10 phút đầu làm chậm lại, thẻ khó trước, thẻ mới sau.”\n\n"
    f"Insight JSON:\n{json.dumps(ins, ensure_ascii=False)}\n\n"
    f"Câu hỏi: {req.question}\n"
)


    try:
        result = gemini_model.generate_content(prompt)
        text = result.text.strip() if result and result.text else ""
        text = _sanitize_coach_text(text)
        if not text:
            return CoachChatResponse(answer=_coach_chat_rule_based(req.question, ins))
        return CoachChatResponse(answer=text)
    except Exception:
        return CoachChatResponse(answer=_coach_chat_rule_based(req.question, ins))



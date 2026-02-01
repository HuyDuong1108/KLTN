# srs_engine.py
# Minimal FSRS engine module for LinguaSquirrel Core.
# APIs: load_scheduler_from_config, load_cards, review, save_progress, log_review
# - Tuân thủ: UTC-only, 4 mức rating (1..4), JSON I/O đơn giản.
# - Không bổ sung tính năng ngoài yêu cầu.

from __future__ import annotations
from pathlib import Path
from datetime import timedelta, datetime, timezone
from typing import Dict, Tuple, Iterable
import os
import json
from fsrs import Scheduler, Card, Rating, ReviewLog


# -----------------------------
# Helpers
# -----------------------------
_RATING_MAP = {
    1: Rating.Again,
    2: Rating.Hard,
    3: Rating.Good,
    4: Rating.Easy,
}

def _to_rating(x: int) -> Rating:
    if x not in _RATING_MAP:
        raise ValueError(f"rating must be 1..4, got {x}")
    return _RATING_MAP[x]


# -----------------------------
# 1) Load scheduler from config
# -----------------------------
def load_scheduler_from_config(cfg_path: Path) -> Scheduler:
    """
    Đọc file JSON cấu hình scheduler đã tối ưu (fsrs_scheduler_optimized.json)
    và khởi tạo Scheduler tương ứng.
    Yêu cầu trường:
      - parameters: list[21 floats]
      - desired_retention: float
      - learning_steps: list[int seconds]
      - relearning_steps: list[int seconds]
      - maximum_interval: int
      - enable_fuzzing: bool
    """
    data = json.loads(Path(cfg_path).read_text(encoding="utf-8"))

    params = data.get("parameters", [])
    if not isinstance(params, list) or len(params) != 21:
        raise ValueError("`parameters` must be a list of length 21.")

    ls = tuple(timedelta(seconds=int(x)) for x in data.get("learning_steps", []))
    rs = tuple(timedelta(seconds=int(x)) for x in data.get("relearning_steps", []))

    sched = Scheduler(
        parameters=tuple(params),
        desired_retention=float(data["desired_retention"]),
        learning_steps=ls,
        relearning_steps=rs,
        maximum_interval=int(data.get("maximum_interval", 36500)),
        enable_fuzzing=bool(data.get("enable_fuzzing", False)),
    )
    return sched


# -----------------------------
# 2) Load / init cards registry
# -----------------------------
def load_cards(cards_path: Path, progress_path: Path) -> Dict[str, Card]:
    """
    Trả về registry: dict[cardId(str) -> fsrs.Card]

    - Nếu progress_path tồn tại:
        Đọc danh sách [{"cardId": str, "card_json": str}], khôi phục Card.from_json(card_json).
    - Nếu chưa tồn tại:
        Tạo Card() mới cho mỗi thẻ, chưa thiết lập gì thêm (FSRS sẽ dùng mặc định).
    """
    registry: Dict[str, Card] = {}

    pp = Path(progress_path)
    if pp.exists():
        raw = None

        # 1) đọc file chính
        try:
            text = pp.read_text(encoding="utf-8").strip()
            if text:
                raw = json.loads(text)
        except json.JSONDecodeError:
            raw = None
        except Exception:
            raw = None

        # 2) fallback: đọc file .tmp (nếu đang atomic write)
        if raw is None:
            tmp = pp.with_suffix(pp.suffix + ".tmp")
            if tmp.exists():
                try:
                    t2 = tmp.read_text(encoding="utf-8").strip()
                    if t2:
                        raw = json.loads(t2)
                except Exception:
                    raw = None

        # 3) nếu raw hợp lệ và có dữ liệu -> restore
        if isinstance(raw, list) and len(raw) > 0:
            for row in raw:
                cid = row["cardId"]
                cjson = row["card_json"]
                registry[cid] = Card.from_json(cjson)
            return registry

    # No progress yet → init from cards source
    src = json.loads(Path(cards_path).read_text(encoding="utf-8"))

    _ = cards_path  # new card: due ngay (theo FSRS)
    return registry

# -----------------------------
# 3) Review 1 thẻ
# -----------------------------
def review(card_id: str, rating: int, scheduler: Scheduler, registry: Dict[str, Card]) -> Tuple[Card, ReviewLog]:
    """
    Thực hiện 1 lần review cho card_id với rating (1..4).
    - Nếu card_id chưa có trong registry: tạo Card() mới (thẻ mới).
    - Cập nhật registry[card_id] và trả về (card, review_log).
    """
    if card_id not in registry:
        # Thẻ mới hoàn toàn → khởi tạo card FSRS mặc định
        registry[card_id] = Card()

    card = registry[card_id]

    r = _to_rating(int(rating))
    card, rlog = scheduler.review_card(card, r)

    registry[card_id] = card  # update state mới sau review
    return card, rlog



# -----------------------------
# 4) Save progress
# -----------------------------
def save_progress(progress_path: Path, registry: Dict[str, Card]) -> None:
    """
    Ghi file progress: [{"cardId": str, "card_json": str}, ...]
    """
    out = [
        {"cardId": cid, "card_json": registry[cid].to_json()}
        for cid in registry.keys()
    ]
    _atomic_write_json(Path(progress_path), out)


# -----------------------------
# 5) Log review (append JSONL)
# -----------------------------
def log_review(log_path: Path, card_id: str, review_log: ReviewLog) -> None:
    """
    Append 1 dòng JSONL: {"cardId","rating","ts"} (UTC ISO-8601 'Z').
    """
    # review_log.review_datetime là UTC (Py-FSRS dùng UTC)
    row = {
        "cardId": card_id,
        "rating": int(review_log.rating),
        "ts": str(review_log.review_datetime).replace("+00:00", "Z"),
    }
    with Path(log_path).open("a", encoding="utf-8") as f:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")

# -----------------------------
# 6) Load policy chọn thẻ
# -----------------------------
def load_policy(policy_path: Path) -> dict:
    """
    Đọc file JSON policy, trả về dict chuẩn:
      {
        "max_new_per_session": int,
        "max_review_per_session": int
      }

    Nếu file không tồn tại hoặc thiếu key,
    dùng default an toàn:
      max_new_per_session = 20
      max_review_per_session = 100

    NOTE: Đây là config, không ảnh hưởng FSRS core.
    """
    if not policy_path.exists():
        return {
            "max_new_per_session": 20,
            "max_review_per_session": 100,
        }

    data = json.loads(policy_path.read_text(encoding="utf-8"))

    max_new = int(
        data.get("max_new_per_session", data.get("max_new", 20))
    )
    max_review = int(
        data.get(
            "max_review_per_session",
            data.get("max_review", 100),
        )
    )

    return {
        "max_new_per_session": max_new,
        "max_review_per_session": max_review,
    }


# -----------------------------
# 7) Policy chọn thẻ: select_cards
# -----------------------------
def select_cards(
    now: datetime,
    registry: Dict[str, Card],
    policy: dict,
) -> list[str]:
    """
    Chọn danh sách cardId cho 1 phiên học, theo policy:

    - Ưu tiên thẻ đã đến hạn (due <= now) và KHÔNG ở state 'New'.
    - Sau đó thêm tối đa max_new_per_session thẻ state 'New'.
    - Không thay đổi FSRS core: chỉ đọc card.state và card.due.

    Args:
      now: datetime hiện tại (UTC hoặc naive, sẽ ép về UTC).
      registry: dict[cardId -> Card] (đang dùng trong app).
      policy: dict từ load_policy(...).

    Returns:
      list[str]: danh sách cardId theo thứ tự gợi ý.
    """
    # Chuẩn hóa now sang UTC
    if now.tzinfo is None:
        now = now.replace(tzinfo=timezone.utc)
    else:
        now = now.astimezone(timezone.utc)

    max_new = int(policy.get("max_new_per_session", 20))
    max_review = int(policy.get("max_review_per_session", 100))

    def _state_name(card: Card) -> str:
        return getattr(card.state, "name", str(card.state))

    due_reviews: list[tuple[str, Card]] = []
    new_cards: list[tuple[str, Card]] = []

    for cid, card in registry.items():
        state = _state_name(card)
        due = card.due

        # Thẻ New
        if state == "New":
            new_cards.append((cid, card))
            continue

        # Thẻ còn lại: chỉ tính các thẻ có due và đã tới hạn
        if due is None:
            continue

        if due.tzinfo is None:
            due_utc = due.replace(tzinfo=timezone.utc)
        else:
            due_utc = due.astimezone(timezone.utc)

        if due_utc <= now:
            due_reviews.append((cid, card))

    # Sort: review đến hạn cũ hơn lên trước
    due_reviews.sort(key=lambda t: t[1].due)

    selected: list[str] = []

    # 1) Lấy review trước: tối đa max_review
    for cid, _ in due_reviews[:max_review]:
        selected.append(cid)

    # 2) Sau đó lấy new: tối đa max_new
    for cid, _ in new_cards[:max_new]:
        selected.append(cid)

    return selected

def _atomic_write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    os.replace(tmp, path)
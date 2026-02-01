import '../models/flashcard_set.dart';
import '../models/vocabulary.dart';

final List<FlashcardSet> communityFlashcardSets = [
  // 1 — Động vật
  FlashcardSet(
    title: "🐶 Động vật",
    description: "Các loài vật cơ bản",
    participants: 240,
    vocabList: [
      Vocabulary(word: "犬", romaji: "inu", meaning: "con chó"),
      Vocabulary(word: "猫", romaji: "neko", meaning: "con mèo"),
      Vocabulary(word: "鳥", romaji: "tori", meaning: "con chim"),
      Vocabulary(word: "牛", romaji: "ushi", meaning: "con bò"),
      Vocabulary(word: "馬", romaji: "uma", meaning: "con ngựa"),
      Vocabulary(word: "豚", romaji: "buta", meaning: "con heo"),
      Vocabulary(word: "羊", romaji: "hitsuji", meaning: "con cừu"),
      Vocabulary(word: "魚", romaji: "sakana", meaning: "con cá"),
      Vocabulary(word: "猿", romaji: "saru", meaning: "con khỉ"),
      Vocabulary(word: "蛇", romaji: "hebi", meaning: "con rắn"),
    ],
  ),

  // 2 — Trường học
  FlashcardSet(
    title: "🏫 Trường học",
    description: "Từ vựng trường lớp",
    participants: 110,
    vocabList: [
      Vocabulary(word: "学校", romaji: "gakkou", meaning: "trường học"),
      Vocabulary(word: "先生", romaji: "sensei", meaning: "giáo viên"),
      Vocabulary(word: "本", romaji: "hon", meaning: "sách"),
      Vocabulary(word: "学生", romaji: "gakusei", meaning: "học sinh"),
      Vocabulary(word: "教室", romaji: "kyoushitsu", meaning: "phòng học"),
      Vocabulary(word: "黒板", romaji: "kokuban", meaning: "bảng đen"),
      Vocabulary(word: "机", romaji: "tsukue", meaning: "bàn học"),
      Vocabulary(word: "椅子", romaji: "isu", meaning: "ghế"),
      Vocabulary(word: "図書館", romaji: "toshokan", meaning: "thư viện"),
      Vocabulary(word: "試験", romaji: "shiken", meaning: "kỳ thi"),
    ],
  ),

  // 3 — Gia đình
  FlashcardSet(
    title: "👪 Gia đình",
    description: "Các thành viên trong gia đình",
    participants: 165,
    vocabList: [
      Vocabulary(word: "家族", romaji: "kazoku", meaning: "gia đình"),
      Vocabulary(word: "父", romaji: "chichi", meaning: "bố"),
      Vocabulary(word: "母", romaji: "haha", meaning: "mẹ"),
      Vocabulary(word: "兄", romaji: "ani", meaning: "anh trai"),
      Vocabulary(word: "姉", romaji: "ane", meaning: "chị gái"),
      Vocabulary(word: "弟", romaji: "otouto", meaning: "em trai"),
      Vocabulary(word: "妹", romaji: "imouto", meaning: "em gái"),
      Vocabulary(word: "祖父", romaji: "sofu", meaning: "ông"),
      Vocabulary(word: "祖母", romaji: "sobo", meaning: "bà"),
      Vocabulary(word: "親戚", romaji: "shinseki", meaning: "họ hàng"),
    ],
  ),

  // 4 — Màu sắc
  FlashcardSet(
    title: "🎨 Màu sắc",
    description: "Những màu cơ bản",
    participants: 98,
    vocabList: [
      Vocabulary(word: "赤", romaji: "aka", meaning: "đỏ"),
      Vocabulary(word: "青", romaji: "ao", meaning: "xanh dương"),
      Vocabulary(word: "緑", romaji: "midori", meaning: "xanh lá"),
      Vocabulary(word: "黄色", romaji: "kiiro", meaning: "vàng"),
      Vocabulary(word: "黒", romaji: "kuro", meaning: "đen"),
      Vocabulary(word: "白", romaji: "shiro", meaning: "trắng"),
      Vocabulary(word: "紫", romaji: "murasaki", meaning: "tím"),
      Vocabulary(word: "灰色", romaji: "haiiro", meaning: "xám"),
      Vocabulary(word: "茶色", romaji: "chairo", meaning: "nâu"),
      Vocabulary(word: "桃色", romaji: "momoiro", meaning: "hồng"),
    ],
  ),

  // 5 — Đồ ăn
  FlashcardSet(
    title: "🍱 Đồ ăn",
    description: "Tên các món ăn cơ bản",
    participants: 220,
    vocabList: [
      Vocabulary(word: "ご飯", romaji: "gohan", meaning: "cơm"),
      Vocabulary(word: "肉", romaji: "niku", meaning: "thịt"),
      Vocabulary(word: "魚", romaji: "sakana", meaning: "cá"),
      Vocabulary(word: "野菜", romaji: "yasai", meaning: "rau"),
      Vocabulary(word: "果物", romaji: "kudamono", meaning: "trái cây"),
      Vocabulary(word: "卵", romaji: "tamago", meaning: "trứng"),
      Vocabulary(word: "味噌汁", romaji: "misoshiru", meaning: "súp miso"),
      Vocabulary(word: "パン", romaji: "pan", meaning: "bánh mì"),
      Vocabulary(word: "寿司", romaji: "sushi", meaning: "sushi"),
      Vocabulary(word: "麺", romaji: "men", meaning: "mì"),
    ],
  ),

  // 6 — Đồ uống
  FlashcardSet(
    title: "🥤 Đồ uống",
    description: "Tên các loại thức uống",
    participants: 145,
    vocabList: [
      Vocabulary(word: "水", romaji: "mizu", meaning: "nước"),
      Vocabulary(word: "お茶", romaji: "ocha", meaning: "trà"),
      Vocabulary(word: "コーヒー", romaji: "koohii", meaning: "cà phê"),
      Vocabulary(word: "牛乳", romaji: "gyuunyuu", meaning: "sữa"),
      Vocabulary(word: "ジュース", romaji: "juusu", meaning: "nước ép"),
      Vocabulary(word: "酒", romaji: "sake", meaning: "rượu sake"),
      Vocabulary(word: "紅茶", romaji: "koucha", meaning: "trà đen"),
      Vocabulary(word: "ソーダ", romaji: "sooda", meaning: "nước ngọt"),
      Vocabulary(word: "緑茶", romaji: "ryokucha", meaning: "trà xanh"),
      Vocabulary(word: "ココア", romaji: "kokoa", meaning: "ca cao"),
    ],
  ),

  // 7 — Động từ cơ bản
  FlashcardSet(
    title: "⚡ Động từ cơ bản",
    description: "Những động từ thường dùng",
    participants: 310,
    vocabList: [
      Vocabulary(word: "行く", romaji: "iku", meaning: "đi"),
      Vocabulary(word: "来る", romaji: "kuru", meaning: "đến"),
      Vocabulary(word: "見る", romaji: "miru", meaning: "xem"),
      Vocabulary(word: "食べる", romaji: "taberu", meaning: "ăn"),
      Vocabulary(word: "飲む", romaji: "nomu", meaning: "uống"),
      Vocabulary(word: "話す", romaji: "hanasu", meaning: "nói"),
      Vocabulary(word: "聞く", romaji: "kiku", meaning: "nghe"),
      Vocabulary(word: "読む", romaji: "yomu", meaning: "đọc"),
      Vocabulary(word: "買う", romaji: "kau", meaning: "mua"),
      Vocabulary(word: "寝る", romaji: "neru", meaning: "ngủ"),
    ],
  ),

  // 8 — Tính từ cơ bản
  FlashcardSet(
    title: "✨ Tính từ cơ bản",
    description: "Những tính từ hay gặp",
    participants: 174,
    vocabList: [
      Vocabulary(word: "大きい", romaji: "ookii", meaning: "to"),
      Vocabulary(word: "小さい", romaji: "chiisai", meaning: "nhỏ"),
      Vocabulary(word: "新しい", romaji: "atarashii", meaning: "mới"),
      Vocabulary(word: "古い", romaji: "furui", meaning: "cũ"),
      Vocabulary(word: "暑い", romaji: "atsui", meaning: "nóng"),
      Vocabulary(word: "寒い", romaji: "samui", meaning: "lạnh"),
      Vocabulary(word: "安い", romaji: "yasui", meaning: "rẻ"),
      Vocabulary(word: "高い", romaji: "takai", meaning: "đắt / cao"),
      Vocabulary(word: "早い", romaji: "hayai", meaning: "nhanh"),
      Vocabulary(word: "遅い", romaji: "osoi", meaning: "chậm"),
    ],
  ),

  // 9 — Thời tiết
  FlashcardSet(
    title: "⛅ Thời tiết",
    description: "Từ vựng về thời tiết",
    participants: 132,
    vocabList: [
      Vocabulary(word: "天気", romaji: "tenki", meaning: "thời tiết"),
      Vocabulary(word: "晴れ", romaji: "hare", meaning: "nắng"),
      Vocabulary(word: "雨", romaji: "ame", meaning: "mưa"),
      Vocabulary(word: "雪", romaji: "yuki", meaning: "tuyết"),
      Vocabulary(word: "風", romaji: "kaze", meaning: "gió"),
      Vocabulary(word: "曇り", romaji: "kumori", meaning: "âm u"),
      Vocabulary(word: "嵐", romaji: "arashi", meaning: "bão"),
      Vocabulary(word: "雷", romaji: "kaminari", meaning: "sấm sét"),
      Vocabulary(word: "湿度", romaji: "shitsudo", meaning: "độ ẩm"),
      Vocabulary(word: "気温", romaji: "kion", meaning: "nhiệt độ"),
    ],
  ),

  // 10 — Địa điểm
  FlashcardSet(
    title: "📍 Địa điểm",
    description: "Những nơi thường gặp",
    participants: 205,
    vocabList: [
      Vocabulary(word: "駅", romaji: "eki", meaning: "ga tàu"),
      Vocabulary(word: "公園", romaji: "kouen", meaning: "công viên"),
      Vocabulary(word: "病院", romaji: "byouin", meaning: "bệnh viện"),
      Vocabulary(word: "銀行", romaji: "ginkou", meaning: "ngân hàng"),
      Vocabulary(word: "店", romaji: "mise", meaning: "cửa hàng"),
      Vocabulary(word: "家", romaji: "ie", meaning: "nhà"),
      Vocabulary(word: "空港", romaji: "kuukou", meaning: "sân bay"),
      Vocabulary(word: "会社", romaji: "kaisha", meaning: "công ty"),
      Vocabulary(word: "ホテル", romaji: "hoteru", meaning: "khách sạn"),
      Vocabulary(word: "海", romaji: "umi", meaning: "biển"),
    ],
  ),

  // 11 — Thời gian
  FlashcardSet(
    title: "⏰ Thời gian",
    description: "Các từ chỉ thời gian",
    participants: 120,
    vocabList: [
      Vocabulary(word: "今日", romaji: "kyou", meaning: "hôm nay"),
      Vocabulary(word: "明日", romaji: "ashita", meaning: "ngày mai"),
      Vocabulary(word: "昨日", romaji: "kinou", meaning: "hôm qua"),
      Vocabulary(word: "朝", romaji: "asa", meaning: "buổi sáng"),
      Vocabulary(word: "昼", romaji: "hiru", meaning: "buổi trưa"),
      Vocabulary(word: "夜", romaji: "yoru", meaning: "buổi tối"),
      Vocabulary(word: "今", romaji: "ima", meaning: "bây giờ"),
      Vocabulary(word: "週", romaji: "shuu", meaning: "tuần"),
      Vocabulary(word: "月", romaji: "tsuki", meaning: "tháng"),
      Vocabulary(word: "年", romaji: "nen", meaning: "năm"),
    ],
  ),

  // 12 — Cảm xúc
  FlashcardSet(
    title: "😊 Cảm xúc",
    description: "Từ vựng cảm xúc cơ bản",
    participants: 180,
    vocabList: [
      Vocabulary(word: "嬉しい", romaji: "ureshii", meaning: "vui"),
      Vocabulary(word: "悲しい", romaji: "kanashii", meaning: "buồn"),
      Vocabulary(word: "怒る", romaji: "okoru", meaning: "giận"),
      Vocabulary(word: "怖い", romaji: "kowai", meaning: "sợ"),
      Vocabulary(word: "楽しい", romaji: "tanoshii", meaning: "vui vẻ"),
      Vocabulary(word: "恥ずかしい", romaji: "hazukashii", meaning: "xấu hổ"),
      Vocabulary(word: "疲れた", romaji: "tsukareta", meaning: "mệt"),
      Vocabulary(word: "安心", romaji: "anshin", meaning: "yên tâm"),
      Vocabulary(word: "緊張", romaji: "kinchou", meaning: "căng thẳng"),
      Vocabulary(word: "退屈", romaji: "taikutsu", meaning: "chán"),
    ],
  ),
];

// Bộ flashcard cá nhân
List<FlashcardSet> personalFlashcardSets = [];

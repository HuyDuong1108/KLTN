import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await seedJapaneseLevel4();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "✅ Japanese learning data seeded successfully\nCheck Firestore",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

Future<void> seedJapaneseLevel4() async {
  final db = FirebaseFirestore.instance;

  final level4Ref = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_4");

  await level4Ref.set({
    "title": "Intermediate",
    "subtitle": "Ngữ pháp – hội thoại – JLPT N4",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Thể て (Te-form)",
      "order": 1,
      "content": {
        "introduction": "Học cách chia động từ sang thể て.",
        "outcome": [
          "Chia động từ thể て",
          "Dùng trong câu mệnh lệnh và nối câu"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"jp": "たべて", "romaji": "tabete", "vi": "hãy ăn"},
              {"jp": "いって", "romaji": "itte", "vi": "hãy đi"},
              {"jp": "みて", "romaji": "mite", "vi": "hãy xem"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Thể て của「たべます」là?",
          "options": ["たべて", "たべた", "たべない"],
          "answer": "たべて"
        },
        {
          "type": "fill",
          "question": "いきます → ___",
          "answer": "いって",
          "options": ["いって", "いきて", "いった", "いかない", "いく"]
        },
        {
          "type": "match",
          "pairs": {
            "たべて": "hãy ăn",
            "いって": "hãy đi",
            "みて": "hãy xem"
          }
        }
      ]
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Thể quá khứ",
      "order": 2,
      "content": {
        "introduction": "Học cách nói việc đã xảy ra.",
        "outcome": [
          "Chia động từ quá khứ",
          "Nói về trải nghiệm"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Quá khứ",
            "items": [
              {"jp": "たべました", "romaji": "tabemashita", "vi": "đã ăn"},
              {"jp": "いきました", "romaji": "ikimashita", "vi": "đã đi"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「いきます」 quá khứ là?",
          "options": ["いきました", "いきます", "いきません"],
          "answer": "いきました"
        },
        {
          "type": "fill",
          "question": "たべます → ___",
          "answer": "たべました",
          "options": ["たべました", "たべます", "たべない", "たべて", "たべよう"]
        },
        {
          "type": "match",
          "pairs": {
            "たべました": "đã ăn",
            "いきました": "đã đi"
          }
        }
      ]
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Thể phủ định",
      "order": 3,
      "content": {
        "introduction": "Cách nói không làm gì đó.",
        "outcome": [
          "Chia phủ định",
          "Dùng trong hội thoại"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Phủ định",
            "items": [
              {"jp": "たべません", "romaji": "tabemasen", "vi": "không ăn"},
              {"jp": "いきません", "romaji": "ikimasen", "vi": "không đi"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Phủ định của「いきます」?",
          "options": ["いきません", "いきました", "いって"],
          "answer": "いきません"
        },
        {
          "type": "fill",
          "question": "たべます → ___",
          "answer": "たべません",
          "options": ["たべません", "たべました", "たべて", "たべない", "たべよう"]
        },
        {
          "type": "match",
          "pairs": {
            "たべません": "không ăn",
            "いきません": "không đi"
          }
        }
      ]
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Mẫu câu ～たい",
      "order": 4,
      "content": {
        "introduction": "Diễn tả mong muốn.",
        "outcome": [
          "Nói muốn làm gì"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Muốn làm",
            "items": [
              {"jp": "たべたい", "romaji": "tabetai", "vi": "muốn ăn"},
              {"jp": "いきたい", "romaji": "ikitai", "vi": "muốn đi"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「いきたい」 nghĩa là?",
          "options": ["Muốn đi", "Đã đi", "Không đi"],
          "answer": "Muốn đi"
        },
        {
          "type": "fill",
          "question": "たべます → ___",
          "answer": "たべたい",
          "options": ["たべたい", "たべました", "たべません", "たべて", "たべよう"]
        },
        {
          "type": "match",
          "pairs": {
            "たべたい": "muốn ăn",
            "いきたい": "muốn đi"
          }
        }
      ]
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Mẫu câu ～ながら",
      "order": 5,
      "content": {
        "introduction": "Diễn tả hai hành động cùng lúc.",
        "outcome": [
          "Nói vừa… vừa…"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "ながら",
            "items": [
              {"jp": "たべながら", "romaji": "tabenagara", "vi": "vừa ăn vừa"},
              {"jp": "ききながら", "romaji": "kikinagara", "vi": "vừa nghe vừa"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「ながら」 dùng để?",
          "options": ["Hai hành động cùng lúc", "Quá khứ", "Phủ định"],
          "answer": "Hai hành động cùng lúc"
        },
        {
          "type": "fill",
          "question": "たべます → ___",
          "answer": "たべながら",
          "options": ["たべながら", "たべたい", "たべました", "たべません", "たべて"]
        },
        {
          "type": "match",
          "pairs": {
            "たべながら": "vừa ăn vừa",
            "ききながら": "vừa nghe vừa"
          }
        }
      ]
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Mẫu câu ～から",
      "order": 6,
      "content": {
        "introduction": "Nói lý do.",
        "outcome": ["Nêu nguyên nhân"],
        "sections": [
          {
            "type": "grammar",
            "title": "から",
            "items": [
              {"jp": "あついから", "romaji": "atsui kara", "vi": "vì nóng"},
              {"jp": "いそがしいから", "romaji": "isogashii kara", "vi": "vì bận"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「から」 dùng để?",
          "options": ["Nêu lý do", "So sánh", "Mệnh lệnh"],
          "answer": "Nêu lý do"
        },
        {
          "type": "fill",
          "question": "あつい ___",
          "answer": "から",
          "options": ["から", "まで", "ので", "と", "が"]
        },
        {
          "type": "match",
          "pairs": {
            "あついから": "vì nóng",
            "いそがしいから": "vì bận"
          }
        }
      ]
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "So sánh",
      "order": 7,
      "content": {
        "introduction": "So sánh hai đối tượng.",
        "outcome": ["So sánh hơn – kém"],
        "sections": [
          {
            "type": "grammar",
            "title": "So sánh",
            "items": [
              {"jp": "Aのほうが", "romaji": "A no hou ga", "vi": "A hơn"},
              {"jp": "Bより", "romaji": "B yori", "vi": "so với B"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Cấu trúc so sánh dùng?",
          "options": ["ほうが", "から", "たい"],
          "answer": "ほうが"
        },
        {
          "type": "fill",
          "question": "B ___ A",
          "answer": "より",
          "options": ["より", "から", "まで", "たい", "て"]
        },
        {
          "type": "match",
          "pairs": {
            "のほうが": "hơn",
            "より": "so với"
          }
        }
      ]
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Thể khả năng",
      "order": 8,
      "content": {
        "introduction": "Diễn tả khả năng làm được.",
        "outcome": ["Nói có thể làm gì"],
        "sections": [
          {
            "type": "grammar",
            "title": "Khả năng",
            "items": [
              {"jp": "できます", "romaji": "dekimasu", "vi": "có thể làm"},
              {"jp": "はなせます", "romaji": "hanasemasu", "vi": "có thể nói"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「できます」 nghĩa là?",
          "options": ["Có thể làm", "Muốn làm", "Đã làm"],
          "answer": "Có thể làm"
        },
        {
          "type": "fill",
          "question": "はなします → ___",
          "answer": "はなせます",
          "options": ["はなせます", "はなしました", "はなします", "はなさない", "はなして"]
        },
        {
          "type": "match",
          "pairs": {
            "できます": "có thể làm",
            "はなせます": "có thể nói"
          }
        }
      ]
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Lời khuyên",
      "order": 9,
      "content": {
        "introduction": "Đưa ra lời khuyên.",
        "outcome": ["Khuyên người khác"],
        "sections": [
          {
            "type": "grammar",
            "title": "～ほうがいい",
            "items": [
              {"jp": "たべたほうがいい", "romaji": "tabetahou ga ii", "vi": "nên ăn"},
              {"jp": "やすんだほうがいい", "romaji": "yasundahou ga ii", "vi": "nên nghỉ"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「ほうがいい」 dùng để?",
          "options": ["Khuyên", "So sánh", "Phủ định"],
          "answer": "Khuyên"
        },
        {
          "type": "fill",
          "question": "やすみます → ___",
          "answer": "やすんだほうがいい",
          "options": [
            "やすんだほうがいい",
            "やすみたい",
            "やすみます",
            "やすみません",
            "やすんで"
          ]
        },
        {
          "type": "match",
          "pairs": {
            "たべたほうがいい": "nên ăn",
            "やすんだほうがいい": "nên nghỉ"
          }
        }
      ]
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập tổng hợp",
      "order": 10,
      "content": {
        "introduction": "Ôn tập toàn bộ Level 4.",
        "outcome": [
          "Củng cố ngữ pháp N4",
          "Chuẩn bị Level 5"
        ],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"jp": "たべて", "romaji": "tabete", "vi": "hãy ăn"},
              {"jp": "いきたい", "romaji": "ikitai", "vi": "muốn đi"},
              {"jp": "できます", "romaji": "dekimasu", "vi": "có thể làm"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「いきたい」 nghĩa là?",
          "options": ["Muốn đi", "Đã đi", "Không đi"],
          "answer": "Muốn đi"
        },
        {
          "type": "fill",
          "question": "たべます → ___",
          "answer": "たべて",
          "options": ["たべて", "たべたい", "たべました", "たべません", "たべよう"]
        },
        {
          "type": "match",
          "pairs": {
            "たべて": "hãy ăn",
            "いきたい": "muốn đi",
            "できます": "có thể làm"
          }
        }
      ]
    },
  };

  for (final entry in lessons.entries) {
    await level4Ref
        .collection("lessons")
        .doc(entry.key)
        .set(entry.value, SetOptions(merge: true));
  }

  debugPrint("🔥 DONE: Japanese Level 4 – 10 lessons, FULL & CHUẨN");
}


Future<void> seedJapaneseLevel2to10() async {
  final db = FirebaseFirestore.instance;

  final level2Ref = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_2");

  await level2Ref.set({
    "title": "Elementary",
    "subtitle": "Từ vựng – ngữ pháp – giao tiếp cơ bản",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Đồ vật quen thuộc",
      "order": 1,
      "content": {
        "introduction":
            "Bài học giúp bạn làm quen với các đồ vật thường gặp trong cuộc sống hằng ngày.",
        "outcome": [
          "Nhận biết đồ vật",
          "Gọi tên đồ vật bằng tiếng Nhật"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Đồ vật",
            "items": [
              {"jp": "ほん", "romaji": "hon", "vi": "sách"},
              {"jp": "ペン", "romaji": "pen", "vi": "bút"},
              {"jp": "かばん", "romaji": "kaban", "vi": "cặp"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「かばん」 nghĩa là gì?",
          "options": ["Sách", "Bút", "Cặp"],
          "answer": "Cặp"
        },
        {
          "type": "fill",
          "question": "ペン = ___",
          "answer": "bút",
          "options": ["bút", "sách", "cặp", "bàn", "ghế"]
        },
        {
          "type": "match",
          "pairs": {
            "ほん": "sách",
            "ペン": "bút",
            "かばん": "cặp"
          }
        }
      ]
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Số đếm 1–10",
      "order": 2,
      "content": {
        "introduction": "Học cách đọc và ghi nhớ các số đếm cơ bản.",
        "outcome": [
          "Đọc số từ 1 đến 10",
          "Sử dụng số trong hội thoại"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Số đếm",
            "items": [
              {"jp": "いち", "romaji": "ichi", "vi": "1"},
              {"jp": "に", "romaji": "ni", "vi": "2"},
              {"jp": "さん", "romaji": "san", "vi": "3"},
              {"jp": "よん", "romaji": "yon", "vi": "4"},
              {"jp": "ご", "romaji": "go", "vi": "5"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Số 4 đọc là?",
          "options": ["よん", "ご", "さん"],
          "answer": "よん"
        },
        {
          "type": "fill",
          "question": "さん = ___",
          "answer": "3",
          "options": ["1", "2", "3", "4", "5"]
        },
        {
          "type": "match",
          "pairs": {
            "いち": "1",
            "に": "2",
            "さん": "3"
          }
        }
      ]
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Gia đình",
      "order": 3,
      "content": {
        "introduction": "Từ vựng về các thành viên trong gia đình.",
        "outcome": [
          "Giới thiệu người thân",
          "Phân biệt vai vế"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Gia đình",
            "items": [
              {"jp": "ちち", "romaji": "chichi", "vi": "bố"},
              {"jp": "はは", "romaji": "haha", "vi": "mẹ"},
              {"jp": "あに", "romaji": "ani", "vi": "anh trai"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「はは」 là ai?",
          "options": ["Bố", "Mẹ", "Anh trai"],
          "answer": "Mẹ"
        },
        {
          "type": "fill",
          "question": "ちち = ___",
          "answer": "bố",
          "options": ["bố", "mẹ", "chị", "em", "ông"]
        },
        {
          "type": "match",
          "pairs": {
            "ちち": "bố",
            "はは": "mẹ",
            "あに": "anh trai"
          }
        }
      ]
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Động từ cơ bản",
      "order": 4,
      "content": {
        "introduction": "Các động từ thường gặp trong sinh hoạt.",
        "outcome": [
          "Nhận biết động từ",
          "Dùng trong câu đơn"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Động từ",
            "items": [
              {"jp": "たべます", "romaji": "tabemasu", "vi": "ăn"},
              {"jp": "のみます", "romaji": "nomimasu", "vi": "uống"},
              {"jp": "いきます", "romaji": "ikimasu", "vi": "đi"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「いきます」 nghĩa là?",
          "options": ["Ăn", "Uống", "Đi"],
          "answer": "Đi"
        },
        {
          "type": "fill",
          "question": "のみます = ___",
          "answer": "uống",
          "options": ["ăn", "uống", "đi", "ngủ", "chạy"]
        },
        {
          "type": "match",
          "pairs": {
            "たべます": "ăn",
            "のみます": "uống",
            "いきます": "đi"
          }
        }
      ]
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Câu khẳng định – phủ định",
      "order": 5,
      "content": {
        "introduction": "Học cách nói là / không phải.",
        "outcome": [
          "Dùng です",
          "Dùng じゃないです"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Cấu trúc",
            "items": [
              {"jp": "～です", "romaji": "desu", "vi": "là"},
              {"jp": "～じゃないです", "romaji": "janai desu", "vi": "không phải"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu phủ định dùng cấu trúc nào?",
          "options": ["です", "じゃないです", "たべます"],
          "answer": "じゃないです"
        },
        {
          "type": "fill",
          "question": "これは学生 ___。",
          "answer": "です",
          "options": ["です", "じゃないです", "のみます", "いきます", "たべます"]
        },
        {
          "type": "match",
          "pairs": {
            "です": "là",
            "じゃないです": "không phải"
          }
        }
      ]
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Màu sắc",
      "order": 6,
      "content": {
        "introduction": "Từ vựng về màu sắc cơ bản.",
        "outcome": ["Gọi tên màu"],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Màu sắc",
            "items": [
              {"jp": "あか", "romaji": "aka", "vi": "đỏ"},
              {"jp": "あお", "romaji": "ao", "vi": "xanh"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「あお」 nghĩa là?",
          "options": ["Đỏ", "Xanh", "Vàng"],
          "answer": "Xanh"
        },
        {
          "type": "fill",
          "question": "あか = ___",
          "answer": "đỏ",
          "options": ["đỏ", "xanh", "trắng", "đen", "vàng"]
        },
        {
          "type": "match",
          "pairs": {
            "あか": "đỏ",
            "あお": "xanh"
          }
        }
      ]
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "Thời gian",
      "order": 7,
      "content": {
        "introduction": "Học từ vựng về thời gian trong ngày.",
        "outcome": ["Nói thời gian"],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Thời gian",
            "items": [
              {"jp": "あさ", "romaji": "asa", "vi": "sáng"},
              {"jp": "よる", "romaji": "yoru", "vi": "tối"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「よる」 là khi nào?",
          "options": ["Sáng", "Trưa", "Tối"],
          "answer": "Tối"
        },
        {
          "type": "fill",
          "question": "あさ = ___",
          "answer": "sáng",
          "options": ["sáng", "tối", "trưa", "đêm", "chiều"]
        },
        {
          "type": "match",
          "pairs": {
            "あさ": "sáng",
            "よる": "tối"
          }
        }
      ]
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Địa điểm",
      "order": 8,
      "content": {
        "introduction": "Từ vựng về địa điểm.",
        "outcome": ["Hỏi – trả lời nơi chốn"],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Địa điểm",
            "items": [
              {"jp": "がっこう", "romaji": "gakkou", "vi": "trường học"},
              {"jp": "いえ", "romaji": "ie", "vi": "nhà"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「がっこう」 là gì?",
          "options": ["Nhà", "Trường học", "Công ty"],
          "answer": "Trường học"
        },
        {
          "type": "fill",
          "question": "いえ = ___",
          "answer": "nhà",
          "options": ["nhà", "trường", "chợ", "cửa hàng", "công ty"]
        },
        {
          "type": "match",
          "pairs": {
            "がっこう": "trường học",
            "いえ": "nhà"
          }
        }
      ]
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Ăn uống",
      "order": 9,
      "content": {
        "introduction": "Từ vựng ăn uống cơ bản.",
        "outcome": ["Gọi tên món ăn"],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Ăn uống",
            "items": [
              {"jp": "ごはん", "romaji": "gohan", "vi": "cơm"},
              {"jp": "みず", "romaji": "mizu", "vi": "nước"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「みず」 nghĩa là?",
          "options": ["Cơm", "Nước", "Trà"],
          "answer": "Nước"
        },
        {
          "type": "fill",
          "question": "ごはん = ___",
          "answer": "cơm",
          "options": ["cơm", "nước", "bánh", "sữa", "trà"]
        },
        {
          "type": "match",
          "pairs": {
            "ごはん": "cơm",
            "みず": "nước"
          }
        }
      ]
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập tổng hợp",
      "order": 10,
      "content": {
        "introduction": "Ôn tập toàn bộ kiến thức Level 2.",
        "outcome": ["Củng cố từ vựng và ngữ pháp"],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"jp": "ほん", "romaji": "hon", "vi": "sách"},
              {"jp": "たべます", "romaji": "tabemasu", "vi": "ăn"},
              {"jp": "がっこう", "romaji": "gakkou", "vi": "trường học"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「たべます」 nghĩa là?",
          "options": ["Ăn", "Uống", "Đi"],
          "answer": "Ăn"
        },
        {
          "type": "fill",
          "question": "がっこう = ___",
          "answer": "trường học",
          "options": ["nhà", "trường học", "cửa hàng", "bệnh viện", "công ty"]
        },
        {
          "type": "match",
          "pairs": {
            "ほん": "sách",
            "たべます": "ăn",
            "がっこう": "trường học"
          }
        }
      ]
    },
  };

  for (final entry in lessons.entries) {
    await level2Ref
        .collection("lessons")
        .doc(entry.key)
        .set(entry.value, SetOptions(merge: true));
  }

  debugPrint("🔥 DONE: Japanese Level 2 – 10 lessons, FULL & CHUẨN");
}
Future<void> seedJapaneseLevel3() async {
  final db = FirebaseFirestore.instance;

  final level3Ref = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_3");

  // --- đảm bảo level_3 tồn tại ---
  await level3Ref.set({
    "title": "Pre-Intermediate",
    "subtitle": "Giao tiếp – ngữ pháp – tình huống thực tế",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Hoạt động hằng ngày",
      "order": 1,
      "content": {
        "introduction":
            "Học cách diễn tả các hoạt động thường ngày bằng tiếng Nhật.",
        "outcome": [
          "Nói hoạt động hằng ngày",
          "Dùng động từ trong ngữ cảnh"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Hoạt động",
            "items": [
              {"jp": "おきます", "romaji": "okimasu", "vi": "thức dậy"},
              {"jp": "ねます", "romaji": "nemasu", "vi": "ngủ"},
              {"jp": "はたらきます", "romaji": "hatarakimasu", "vi": "làm việc"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「ねます」 nghĩa là?",
          "options": ["Ngủ", "Thức dậy", "Làm việc"],
          "answer": "Ngủ"
        },
        {
          "type": "fill",
          "question": "おきます = ___",
          "answer": "thức dậy",
          "options": ["ngủ", "thức dậy", "làm việc", "ăn", "đi"]
        },
        {
          "type": "match",
          "pairs": {
            "おきます": "thức dậy",
            "ねます": "ngủ",
            "はたらきます": "làm việc"
          }
        }
      ]
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Địa điểm công cộng",
      "order": 2,
      "content": {
        "introduction": "Học từ vựng về các địa điểm thường gặp.",
        "outcome": [
          "Hỏi – trả lời địa điểm",
          "Giao tiếp khi đi lại"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Địa điểm",
            "items": [
              {"jp": "えき", "romaji": "eki", "vi": "ga"},
              {"jp": "びょういん", "romaji": "byouin", "vi": "bệnh viện"},
              {"jp": "ぎんこう", "romaji": "ginkou", "vi": "ngân hàng"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「えき」 là gì?",
          "options": ["Ga", "Bệnh viện", "Ngân hàng"],
          "answer": "Ga"
        },
        {
          "type": "fill",
          "question": "びょういん = ___",
          "answer": "bệnh viện",
          "options": ["bệnh viện", "ga", "ngân hàng", "trường", "nhà"]
        },
        {
          "type": "match",
          "pairs": {
            "えき": "ga",
            "びょういん": "bệnh viện",
            "ぎんこう": "ngân hàng"
          }
        }
      ]
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Phương tiện giao thông",
      "order": 3,
      "content": {
        "introduction": "Từ vựng về các phương tiện di chuyển.",
        "outcome": [
          "Gọi tên phương tiện",
          "Nói cách di chuyển"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Phương tiện",
            "items": [
              {"jp": "でんしゃ", "romaji": "densha", "vi": "tàu điện"},
              {"jp": "バス", "romaji": "basu", "vi": "xe buýt"},
              {"jp": "じてんしゃ", "romaji": "jitensha", "vi": "xe đạp"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「バス」 là gì?",
          "options": ["Xe buýt", "Tàu điện", "Xe đạp"],
          "answer": "Xe buýt"
        },
        {
          "type": "fill",
          "question": "でんしゃ = ___",
          "answer": "tàu điện",
          "options": ["tàu điện", "xe buýt", "xe đạp", "máy bay", "tàu thuỷ"]
        },
        {
          "type": "match",
          "pairs": {
            "でんしゃ": "tàu điện",
            "バス": "xe buýt",
            "じてんしゃ": "xe đạp"
          }
        }
      ]
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Thời tiết",
      "order": 4,
      "content": {
        "introduction": "Học cách nói về thời tiết.",
        "outcome": [
          "Mô tả thời tiết",
          "Hiểu hội thoại đơn giản"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Thời tiết",
            "items": [
              {"jp": "はれ", "romaji": "hare", "vi": "nắng"},
              {"jp": "あめ", "romaji": "ame", "vi": "mưa"},
              {"jp": "くもり", "romaji": "kumori", "vi": "nhiều mây"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「あめ」 nghĩa là?",
          "options": ["Mưa", "Nắng", "Mây"],
          "answer": "Mưa"
        },
        {
          "type": "fill",
          "question": "はれ = ___",
          "answer": "nắng",
          "options": ["nắng", "mưa", "gió", "lạnh", "mây"]
        },
        {
          "type": "match",
          "pairs": {
            "はれ": "nắng",
            "あめ": "mưa",
            "くもり": "nhiều mây"
          }
        }
      ]
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Sở thích",
      "order": 5,
      "content": {
        "introduction": "Nói về sở thích cá nhân.",
        "outcome": [
          "Nói thích / không thích",
          "Giao tiếp đơn giản"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Sở thích",
            "items": [
              {"jp": "えいが", "romaji": "eiga", "vi": "phim"},
              {"jp": "おんがく", "romaji": "ongaku", "vi": "âm nhạc"},
              {"jp": "スポーツ", "romaji": "supootsu", "vi": "thể thao"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「おんがく」 là gì?",
          "options": ["Âm nhạc", "Phim", "Thể thao"],
          "answer": "Âm nhạc"
        },
        {
          "type": "fill",
          "question": "えいが = ___",
          "answer": "phim",
          "options": ["phim", "nhạc", "thể thao", "sách", "truyện"]
        },
        {
          "type": "match",
          "pairs": {
            "えいが": "phim",
            "おんがく": "âm nhạc",
            "スポーツ": "thể thao"
          }
        }
      ]
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Ăn ngoài",
      "order": 6,
      "content": {
        "introduction": "Từ vựng khi đi ăn nhà hàng.",
        "outcome": [
          "Gọi món",
          "Hiểu menu đơn giản"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Nhà hàng",
            "items": [
              {"jp": "レストラン", "romaji": "resutoran", "vi": "nhà hàng"},
              {"jp": "メニュー", "romaji": "menyuu", "vi": "thực đơn"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「メニュー」 là gì?",
          "options": ["Thực đơn", "Nhà hàng", "Bếp"],
          "answer": "Thực đơn"
        },
        {
          "type": "fill",
          "question": "レストラン = ___",
          "answer": "nhà hàng",
          "options": ["nhà hàng", "cửa hàng", "trường", "nhà", "quán"]
        },
        {
          "type": "match",
          "pairs": {
            "レストラン": "nhà hàng",
            "メニュー": "thực đơn"
          }
        }
      ]
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "Mua sắm",
      "order": 7,
      "content": {
        "introduction": "Học từ vựng và mẫu câu khi mua sắm.",
        "outcome": [
          "Hỏi giá",
          "Mua đồ đơn giản"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Mua sắm",
            "items": [
              {"jp": "みせ", "romaji": "mise", "vi": "cửa hàng"},
              {"jp": "ねだん", "romaji": "nedan", "vi": "giá tiền"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「ねだん」 nghĩa là?",
          "options": ["Giá tiền", "Cửa hàng", "Tiền"],
          "answer": "Giá tiền"
        },
        {
          "type": "fill",
          "question": "みせ = ___",
          "answer": "cửa hàng",
          "options": ["cửa hàng", "nhà", "chợ", "siêu thị", "trường"]
        },
        {
          "type": "match",
          "pairs": {
            "みせ": "cửa hàng",
            "ねだん": "giá tiền"
          }
        }
      ]
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Cảm xúc",
      "order": 8,
      "content": {
        "introduction": "Từ vựng diễn tả cảm xúc.",
        "outcome": [
          "Diễn tả cảm xúc",
          "Hiểu trạng thái người khác"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Cảm xúc",
            "items": [
              {"jp": "うれしい", "romaji": "ureshii", "vi": "vui"},
              {"jp": "かなしい", "romaji": "kanashii", "vi": "buồn"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「かなしい」 là?",
          "options": ["Vui", "Buồn", "Giận"],
          "answer": "Buồn"
        },
        {
          "type": "fill",
          "question": "うれしい = ___",
          "answer": "vui",
          "options": ["vui", "buồn", "tức giận", "mệt", "lo"]
        },
        {
          "type": "match",
          "pairs": {
            "うれしい": "vui",
            "かなしい": "buồn"
          }
        }
      ]
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Sức khoẻ",
      "order": 9,
      "content": {
        "introduction": "Từ vựng khi nói về sức khoẻ.",
        "outcome": [
          "Mô tả tình trạng sức khoẻ"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Sức khoẻ",
            "items": [
              {"jp": "いたい", "romaji": "itai", "vi": "đau"},
              {"jp": "げんき", "romaji": "genki", "vi": "khoẻ"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「げんき」 nghĩa là?",
          "options": ["Khoẻ", "Đau", "Mệt"],
          "answer": "Khoẻ"
        },
        {
          "type": "fill",
          "question": "いたい = ___",
          "answer": "đau",
          "options": ["đau", "khoẻ", "mệt", "buồn", "vui"]
        },
        {
          "type": "match",
          "pairs": {
            "いたい": "đau",
            "げんき": "khoẻ"
          }
        }
      ]
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập tổng hợp",
      "order": 10,
      "content": {
        "introduction": "Ôn tập toàn bộ kiến thức Level 3.",
        "outcome": [
          "Củng cố giao tiếp",
          "Sẵn sàng lên Level 4"
        ],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"jp": "えき", "romaji": "eki", "vi": "ga"},
              {"jp": "うれしい", "romaji": "ureshii", "vi": "vui"},
              {"jp": "レストラン", "romaji": "resutoran", "vi": "nhà hàng"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「えき」 là gì?",
          "options": ["Ga", "Nhà hàng", "Bệnh viện"],
          "answer": "Ga"
        },
        {
          "type": "fill",
          "question": "レストラン = ___",
          "answer": "nhà hàng",
          "options": ["nhà hàng", "ga", "trường", "nhà", "quán"]
        },
        {
          "type": "match",
          "pairs": {
            "えき": "ga",
            "うれしい": "vui",
            "レストラン": "nhà hàng"
          }
        }
      ]
    },
  };

  for (final entry in lessons.entries) {
    await level3Ref
        .collection("lessons")
        .doc(entry.key)
        .set(entry.value, SetOptions(merge: true));
  }

  debugPrint("🔥 DONE: Japanese Level 3 10 lessons, FULL & CHUẨN");
}


Future<void> seedJapaneseLevel2() async {
  final db = FirebaseFirestore.instance;

  final level2Ref = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_2");

  // --- đảm bảo level_2 tồn tại ---
  await level2Ref.set({
    "title": "Elementary",
    "subtitle": "Từ vựng & mẫu câu cơ bản",
  }, SetOptions(merge: true));

  final lessons = {
    "lesson_1": {
      "title": "Từ vựng đồ vật",
      "order": 1,
      "content": {
        "introduction": "Trong bài học này, bạn sẽ học các đồ vật quen thuộc xung quanh.",
        "outcome": [
          "Nhận biết từ vựng đồ vật",
          "Sử dụng trong câu đơn giản"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Đồ vật",
            "items": [
              {"jp": "ほん", "romaji": "hon", "vi": "sách"},
              {"jp": "ペン", "romaji": "pen", "vi": "bút"},
              {"jp": "かばん", "romaji": "kaban", "vi": "cặp"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「ほん」 nghĩa là gì?",
          "options": ["Bút", "Sách", "Cặp"],
          "answer": "Sách"
        },
        {
          "type": "fill",
          "question": "ペン = ___",
          "answer": "Bút",
          "options": ["Sách", "Bút", "Cặp", "Nhà", "Ghế"]
        }
      ]
    },

    "lesson_2": {
      "title": "Số đếm 1–10",
      "order": 2,
      "content": {
        "introduction": "Học số đếm cơ bản từ 1 đến 10 trong tiếng Nhật.",
        "outcome": [
          "Nhớ số đếm cơ bản",
          "Dùng để nói tuổi và số lượng"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Số đếm",
            "items": [
              {"jp": "いち", "romaji": "ichi", "vi": "1"},
              {"jp": "に", "romaji": "ni", "vi": "2"},
              {"jp": "さん", "romaji": "san", "vi": "3"},
              {"jp": "よん", "romaji": "yon", "vi": "4"},
              {"jp": "ご", "romaji": "go", "vi": "5"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Số 3 đọc là?",
          "options": ["に", "さん", "ご"],
          "answer": "さん"
        }
      ]
    },

    "lesson_3": {
      "title": "Gia đình",
      "order": 3,
      "content": {
        "introduction": "Học từ vựng cơ bản về gia đình.",
        "outcome": [
          "Giới thiệu người thân",
          "Nhận biết từ xưng hô"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Gia đình",
            "items": [
              {"jp": "ちち", "romaji": "chichi", "vi": "bố"},
              {"jp": "はは", "romaji": "haha", "vi": "mẹ"},
              {"jp": "あに", "romaji": "ani", "vi": "anh trai"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "match",
          "pairs": {
            "ちち": "bố",
            "はは": "mẹ",
            "あに": "anh trai"
          }
        }
      ]
    },

    "lesson_4": {
      "title": "Động từ cơ bản",
      "order": 4,
      "content": {
        "introduction": "Làm quen với các động từ thường dùng.",
        "outcome": [
          "Nhận biết động từ",
          "Dùng trong câu đơn"
        ],
        "sections": [
          {
            "type": "vocabulary",
            "title": "Động từ",
            "items": [
              {"jp": "たべます", "romaji": "tabemasu", "vi": "ăn"},
              {"jp": "のみます", "romaji": "nomimasu", "vi": "uống"},
              {"jp": "いきます", "romaji": "ikimasu", "vi": "đi"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "「たべます」 nghĩa là?",
          "options": ["Uống", "Ăn", "Đi"],
          "answer": "Ăn"
        }
      ]
    },

    "lesson_5": {
      "title": "Câu khẳng định – phủ định",
      "order": 5,
      "content": {
        "introduction": "Học cách nói câu khẳng định và phủ định.",
        "outcome": [
          "Nói câu khẳng định",
          "Nói câu phủ định"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Cấu trúc",
            "items": [
              {"jp": "～です", "romaji": "desu", "vi": "là"},
              {"jp": "～じゃないです", "romaji": "janai desu", "vi": "không phải"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "fill",
          "question": "これは本 ___。",
          "answer": "です",
          "options": ["です", "じゃないです", "たべます", "いきます", "のみます"]
        }
      ]
    }
  };

  for (final entry in lessons.entries) {
    await level2Ref
        .collection("lessons")
        .doc(entry.key)
        .set({
          "title": entry.value["title"],
          "order": entry.value["order"],
          "content": entry.value["content"],
          "test": entry.value["test"],
        }, SetOptions(merge: true));

    debugPrint("✅ Updated ${entry.key} (level_2)");
  }

  debugPrint("🔥 DONE: Japanese level_2 (5 lessons) seeded correctly");
}

Future<void> migrateFillQuestionsToChoice() async {
  final db = FirebaseFirestore.instance;

  final lessonsRef = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_1")
      .collection("lessons");

  final snapshot = await lessonsRef.get();

  // 🔹 Từ nhiễu dùng chung cho beginner
  final distractors = [
    "わたし",
    "あなた",
    "かれ",
    "かのじょ",
    "あのひと",
    "それ",
    "これ",
    "あれ",
    "ここ",
    "そこ"
  ];

  for (final lesson in snapshot.docs) {
    final data = lesson.data();
    if (!data.containsKey("test")) continue;

    final List tests = List.from(data["test"]);
    bool updated = false;

    final newTests = tests.map((q) {
      if (q["type"] == "fill" && q["options"] == null) {
        final String answer = q["answer"];

        // 👉 Tạo options (đáp án + nhiễu)
        final options = <String>{answer};

        for (final d in distractors) {
          if (options.length >= 5) break;
          if (d != answer) options.add(d);
        }

        updated = true;

        return {
          ...q,
          "options": options.toList()..shuffle(),
        };
      }

      return q;
    }).toList();

    if (updated) {
      await lesson.reference.update({"test": newTests});
      debugPrint("✅ Migrated fill → choice in ${lesson.id}");
    }
  }

  debugPrint("🔥 DONE: All fill questions converted");
}

Future<void> updateLesson2To10Content() async {
  final db = FirebaseFirestore.instance;

  final lessons = {
    "lesson_2": {
      "introduction": "Học các câu chào hỏi cơ bản trong giao tiếp hằng ngày.",
      "outcome": [
        "Biết cách chào hỏi theo thời điểm",
        "Phản xạ chào hỏi tự nhiên"
      ],
      "sections": [
        {
          "type": "sentence",
          "title": "Câu chào hỏi",
          "items": [
            {"jp": "おはよう", "romaji": "ohayou", "vi": "Chào buổi sáng"},
            {"jp": "こんにちは", "romaji": "konnichiwa", "vi": "Xin chào"},
            {"jp": "こんばんは", "romaji": "konbanwa", "vi": "Chào buổi tối"}
          ]
        }
      ]
    },

    "lesson_3": {
      "introduction": "Học cách giới thiệu bản thân bằng tiếng Nhật.",
      "outcome": [
        "Biết giới thiệu tên",
        "Hiểu cấu trúc câu ～です"
      ],
      "sections": [
        {
          "type": "sentence",
          "title": "Giới thiệu bản thân",
          "items": [
            {"jp": "わたしはアンです。", "romaji": "watashi wa An desu", "vi": "Tôi là An"},
            {"jp": "はじめまして。", "romaji": "hajimemashite", "vi": "Rất vui được gặp bạn"}
          ]
        }
      ]
    },

    "lesson_4": {
      "introduction": "Làm quen với số đếm từ 1 đến 5.",
      "outcome": [
        "Nhớ số cơ bản",
        "Ứng dụng vào tuổi, số lượng"
      ],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Số đếm",
          "items": [
            {"jp": "いち", "romaji": "ichi", "vi": "1"},
            {"jp": "に", "romaji": "ni", "vi": "2"},
            {"jp": "さん", "romaji": "san", "vi": "3"},
            {"jp": "よん", "romaji": "yon", "vi": "4"},
            {"jp": "ご", "romaji": "go", "vi": "5"}
          ]
        }
      ]
    },

    "lesson_5": {
      "introduction": "Từ vựng các đồ vật quen thuộc.",
      "outcome": [
        "Gọi tên đồ vật xung quanh",
        "Mở rộng vốn từ"
      ],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Đồ vật",
          "items": [
            {"jp": "ほん", "romaji": "hon", "vi": "Sách"},
            {"jp": "ペン", "romaji": "pen", "vi": "Bút"},
            {"jp": "かばん", "romaji": "kaban", "vi": "Cặp"}
          ]
        }
      ]
    },

    "lesson_6": {
      "introduction": "Học cách nói câu khẳng định và phủ định.",
      "outcome": [
        "Nói câu khẳng định",
        "Nói câu phủ định"
      ],
      "sections": [
        {
          "type": "grammar",
          "title": "Cấu trúc câu",
          "items": [
            {"jp": "～です", "romaji": "desu", "vi": "là"},
            {"jp": "～じゃないです", "romaji": "janai desu", "vi": "không phải"}
          ]
        }
      ]
    },

    "lesson_7": {
      "introduction": "Học từ vựng về gia đình.",
      "outcome": [
        "Giới thiệu gia đình",
        "Nhận biết từ xưng hô"
      ],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Gia đình",
          "items": [
            {"jp": "ちち", "romaji": "chichi", "vi": "Bố"},
            {"jp": "はは", "romaji": "haha", "vi": "Mẹ"},
            {"jp": "あに", "romaji": "ani", "vi": "Anh trai"}
          ]
        }
      ]
    },

    "lesson_8": {
      "introduction": "Các từ chỉ thời gian thường dùng.",
      "outcome": [
        "Nói về thời gian",
        "Hiểu ngữ cảnh câu"
      ],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Thời gian",
          "items": [
            {"jp": "きょう", "romaji": "kyou", "vi": "Hôm nay"},
            {"jp": "あした", "romaji": "ashita", "vi": "Ngày mai"},
            {"jp": "いま", "romaji": "ima", "vi": "Bây giờ"}
          ]
        }
      ]
    },

    "lesson_9": {
      "introduction": "Các động từ cơ bản trong sinh hoạt.",
      "outcome": [
        "Nhận biết động từ",
        "Sử dụng trong câu đơn"
      ],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Động từ",
          "items": [
            {"jp": "たべます", "romaji": "tabemasu", "vi": "Ăn"},
            {"jp": "のみます", "romaji": "nomimasu", "vi": "Uống"},
            {"jp": "いきます", "romaji": "ikimasu", "vi": "Đi"}
          ]
        }
      ]
    },

    "lesson_10": {
      "introduction": "Hội thoại chào hỏi và hỏi tên.",
      "outcome": [
        "Thực hành hội thoại",
        "Phản xạ giao tiếp"
      ],
      "sections": [
        {
          "type": "sentence",
          "title": "Hội thoại",
          "items": [
            {"jp": "こんにちは", "romaji": "konnichiwa", "vi": "Xin chào"},
            {"jp": "なまえは？", "romaji": "namae wa?", "vi": "Tên bạn là gì?"},
            {"jp": "アンです。", "romaji": "An desu", "vi": "Tôi là An"}
          ]
        }
      ]
    }
  };

  for (final entry in lessons.entries) {
    await db
        .collection("languages")
        .doc("ja")
        .collection("courses")
        .doc("level_1")
        .collection("lessons")
        .doc(entry.key)
        .update({"content": entry.value});

    debugPrint("✅ Updated ${entry.key}");
  }

  debugPrint("🔥 ALL lesson 2 → 10 UPDATED");
}


Future<void> updateLesson1Content() async {
  final db = FirebaseFirestore.instance;

  final lessonRef = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_1")
      .collection("lessons")
      .doc("lesson_1");

  final newContent = {
    "introduction":
        "Trong bài học này, bạn sẽ làm quen với 5 chữ Hiragana đầu tiên trong tiếng Nhật.",
    "outcome": [
      "Nhận biết và đọc đúng あ・い・う・え・お",
      "Phát âm chuẩn tiếng Nhật",
      "Biết cách ghép chữ đơn giản"
    ],
    "sections": [
      {
        "type": "phonetic",
        "title": "Ngữ âm Hiragana",
        "items": [
          {
            "jp": "あ",
            "romaji": "a",
            "vi": "a",
            "image":
"https://trungtamnhatngu.edu.vn/uploads/blog/2018_08/hoc-bang-chu-cai-tieng-nhat.jpg"          },
          {
            "jp": "い",
            "romaji": "i",
            "vi": "i",
            "image":
"https://trungtamnhatngu.edu.vn/uploads/blog/2018_08/hoc-bang-chu-cai-tieng-nhat.jpg"          },
          {
            "jp": "う",
            "romaji": "u",
            "vi": "u",
            "image":
"https://trungtamnhatngu.edu.vn/uploads/blog/2018_08/hoc-bang-chu-cai-tieng-nhat.jpg"          },
          {
            "jp": "え",
            "romaji": "e",
            "vi": "e",
            "image":
"https://trungtamnhatngu.edu.vn/uploads/blog/2018_08/hoc-bang-chu-cai-tieng-nhat.jpg"          },
          {
            "jp": "お",
            "romaji": "o",
            "vi": "o",
            "image":
"https://trungtamnhatngu.edu.vn/uploads/blog/2018_08/hoc-bang-chu-cai-tieng-nhat.jpg"          }
        ]
      },
      {
        "type": "example",
        "title": "Từ ghép đơn giản",
        "items": [
          {
            "jp": "あい",
            "romaji": "ai",
            "vi": "tình yêu"
          },
          {
            "jp": "うえ",
            "romaji": "ue",
            "vi": "phía trên"
          }
        ]
      }
    ]
  };

  await lessonRef.update({
    "content": newContent,
  });

  debugPrint("🔥 lesson_1 content UPDATED");
}

Future<void> updateLessonOrderLevel1() async {
  final db = FirebaseFirestore.instance;

  final lessonsRef = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_1")
      .collection("lessons");

  final snapshot = await lessonsRef.get();

  for (final doc in snapshot.docs) {
    final docId = doc.id; // lesson_1, lesson_10, ...

    // 👉 Tách số từ lesson_x
    final match = RegExp(r'lesson_(\d+)').firstMatch(docId);

    if (match == null) {
      debugPrint("⚠️ Skip $docId (invalid format)");
      continue;
    }

    final order = int.parse(match.group(1)!);

    await doc.reference.update({
      "order": order,
    });

    debugPrint("✅ Updated $docId → order = $order");
  }

  debugPrint("🔥 DONE: order field added to all lessons");
}


Future<void> addMoreLessonsLevel1() async {
  final db = FirebaseFirestore.instance;

  final level1Lessons = db
      .collection("languages")
      .doc("ja")
      .collection("courses")
      .doc("level_1")
      .collection("lessons");

  final newLessons = [
    {
      "id": "lesson_3",
      "title": "Giới thiệu bản thân",
      "content": """
## Giới thiệu bản thân

- わたし : Tôi
- なまえ : Tên

Mẫu câu:
- わたしはアンです。
""",
      "test": [
        {
          "type": "choice",
          "question": "Câu nào dùng để giới thiệu bản thân?",
          "options": ["ありがとう", "わたしはアンです", "さようなら"],
          "answer": "わたしはアンです"
        },
        {
          "type": "fill",
          "question": "___ は アン です。",
          "answer": "わたし"
        },
        {
          "type": "match",
          "pairs": {
            "わたし": "Tôi",
            "なまえ": "Tên"
          }
        }
      ]
    },

    {
      "id": "lesson_4",
      "title": "Số đếm & tuổi",
      "content": """
## Số đếm

- いち : 1
- に : 2
- さん : 3
- よん : 4
- ご : 5
""",
      "test": [
        {
          "type": "choice",
          "question": "Số 4 đọc là?",
          "options": ["さん", "よん", "ご"],
          "answer": "よん"
        },
        {
          "type": "fill",
          "question": "さん = ___",
          "answer": "3"
        },
        {
          "type": "match",
          "pairs": {
            "いち": "1",
            "に": "2",
            "さん": "3"
          }
        }
      ]
    },

    {
      "id": "lesson_5",
      "title": "Đồ vật quen thuộc",
      "content": """
## Đồ vật

- ほん : Sách
- ペン : Bút
- かばん : Cặp
""",
      "test": [
        {
          "type": "choice",
          "question": "ほん là gì?",
          "options": ["Bút", "Sách", "Cặp"],
          "answer": "Sách"
        },
        {
          "type": "fill",
          "question": "ペン = ___",
          "answer": "Bút"
        },
        {
          "type": "match",
          "pairs": {
            "ほん": "Sách",
            "ペン": "Bút",
            "かばん": "Cặp"
          }
        }
      ]
    },

    {
      "id": "lesson_6",
      "title": "Câu khẳng định – phủ định",
      "content": """
## Khẳng định & phủ định

- ～です : là
- ～じゃないです : không phải
""",
      "test": [
        {
          "type": "choice",
          "question": "Câu phủ định là?",
          "options": ["です", "じゃないです", "ます"],
          "answer": "じゃないです"
        },
        {
          "type": "fill",
          "question": "ほん ___。",
          "answer": "じゃないです"
        },
        {
          "type": "match",
          "pairs": {
            "です": "là",
            "じゃないです": "không phải"
          }
        }
      ]
    },

    {
      "id": "lesson_7",
      "title": "Gia đình",
      "content": """
## Gia đình

- ちち : Bố
- はは : Mẹ
- あに : Anh trai
""",
      "test": [
        {
          "type": "choice",
          "question": "はは là ai?",
          "options": ["Bố", "Mẹ", "Anh"],
          "answer": "Mẹ"
        },
        {
          "type": "fill",
          "question": "___ は ちち です。",
          "answer": "それ"
        },
        {
          "type": "match",
          "pairs": {
            "ちち": "Bố",
            "はは": "Mẹ",
            "あに": "Anh trai"
          }
        }
      ]
    },

    {
      "id": "lesson_8",
      "title": "Thời gian – ngày tháng",
      "content": """
## Thời gian

- きょう : Hôm nay
- あした : Ngày mai
- いま : Bây giờ
""",
      "test": [
        {
          "type": "choice",
          "question": "きょう nghĩa là?",
          "options": ["Hôm nay", "Ngày mai", "Hôm qua"],
          "answer": "Hôm nay"
        },
        {
          "type": "fill",
          "question": "いま = ___",
          "answer": "Bây giờ"
        },
        {
          "type": "match",
          "pairs": {
            "きょう": "Hôm nay",
            "あした": "Ngày mai",
            "いま": "Bây giờ"
          }
        }
      ]
    },

    {
      "id": "lesson_9",
      "title": "Động từ cơ bản",
      "content": """
## Động từ

- たべます : Ăn
- のみます : Uống
- いきます : Đi
""",
      "test": [
        {
          "type": "choice",
          "question": "たべます nghĩa là?",
          "options": ["Uống", "Ăn", "Đi"],
          "answer": "Ăn"
        },
        {
          "type": "fill",
          "question": "のみます = ___",
          "answer": "Uống"
        },
        {
          "type": "match",
          "pairs": {
            "たべます": "Ăn",
            "のみます": "Uống",
            "いきます": "Đi"
          }
        }
      ]
    },

    {
      "id": "lesson_10",
      "title": "Hội thoại đơn giản",
      "content": """
## Hội thoại

- A: こんにちは
- B: こんにちは
- A: なまえは？
- B: アンです。
""",
      "test": [
        {
          "type": "choice",
          "question": "なまえは？ nghĩa là?",
          "options": ["Xin chào", "Tên bạn là gì?", "Bạn khỏe không?"],
          "answer": "Tên bạn là gì?"
        },
        {
          "type": "fill",
          "question": "___ です。",
          "answer": "アン"
        },
        {
          "type": "match",
          "pairs": {
            "こんにちは": "Xin chào",
            "なまえ": "Tên",
            "です": "là"
          }
        }
      ]
    }
  ];

  for (final lesson in newLessons) {
    await level1Lessons.doc(lesson["id"] as String).set({
      "title": lesson["title"],
      "content": lesson["content"],
      "test": lesson["test"],
    });
  }

  debugPrint("✅ Added lesson_3 → lesson_10 to level_1");
}


Future<void> seedJapaneseData() async {
  final db = FirebaseFirestore.instance;

  final ja = db.collection("languages").doc("ja");

  await ja.set({"name": "Japanese"});

  final levels = [
    {
      "id": "level_1",
      "title": "Beginner",
      "subtitle": "Học bảng chữ & chào hỏi",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Hiragana あ–お",
          "content": """
## Hiragana あ–お

### Bảng chữ
- あ (a)
- い (i)
- う (u)
- え (e)
- お (o)

### Ví dụ
- あい (tình yêu)
- うえ (phía trên)
""",
          "test": [
            {
              "type": "choice",
              "question": "Chữ nào đọc là **a**?",
              "options": ["い", "あ", "う"],
              "answer": "あ"
            },
            {
              "type": "fill",
              "question": "Điền chữ đúng: ___ え (trên)",
              "answer": "う"
            },
            {
              "type": "match",
              "pairs": {
                "あ": "a",
                "い": "i",
                "う": "u"
              }
            }
          ]
        },
        {
          "id": "lesson_2",
          "title": "Chào hỏi cơ bản",
          "content": """
## Chào hỏi cơ bản

- おはよう : Chào buổi sáng
- こんにちは : Xin chào
- こんばんは : Chào buổi tối
""",
          "test": [
            {
              "type": "choice",
              "question": "Câu nào dùng buổi sáng?",
              "options": ["こんばんは", "こんにちは", "おはよう"],
              "answer": "おはよう"
            },
            {
              "type": "fill",
              "question": "Điền từ: ___ はよう",
              "answer": "お"
            },
            {
              "type": "match",
              "pairs": {
                "おはよう": "Chào sáng",
                "こんにちは": "Xin chào",
                "こんばんは": "Chào tối"
              }
            }
          ]
        }
      ]
    },
    {
      "id": "level_2",
      "title": "Elementary",
      "subtitle": "Từ vựng & ngữ pháp N5",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Giới thiệu bản thân",
          "content": """
## Giới thiệu bản thân

Mẫu câu:
- わたしはナムです。
- はじめまして。
""",
          "test": [
            {
              "type": "choice",
              "question": "Câu nào dùng để tự giới thiệu?",
              "options": ["はじめまして", "さようなら", "ありがとう"],
              "answer": "はじめまして"
            },
            {
              "type": "fill",
              "question": "___ は ナム です。",
              "answer": "わたし"
            },
            {
              "type": "match",
              "pairs": {
                "ありがとう": "Cảm ơn",
                "さようなら": "Tạm biệt",
                "はじめまして": "Rất vui được gặp"
              }
            }
          ]
        },
        {
          "id": "lesson_2",
          "title": "Số đếm 1–10",
          "content": """
## Số đếm

1 いち  
2 に  
3 さん  
4 よん  
5 ご  
""",
          "test": [
            {
              "type": "choice",
              "question": "Số 3 đọc là gì?",
              "options": ["に", "さん", "よん"],
              "answer": "さん"
            },
            {
              "type": "fill",
              "question": "Điền số: よん = ___",
              "answer": "4"
            },
            {
              "type": "match",
              "pairs": {
                "いち": "1",
                "に": "2",
                "さん": "3"
              }
            }
          ]
        }
      ]
    },
    {
      "id": "level_3",
      "title": "Pre-Intermediate",
      "subtitle": "Ngữ pháp N4",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Thể て",
          "content": """
## Thể て

Ví dụ:
- たべる → たべて
- のむ → のんで
""",
          "test": [
            {
              "type": "choice",
              "question": "Thể て của のむ là?",
              "options": ["のんで", "のみて", "のむて"],
              "answer": "のんで"
            },
            {
              "type": "fill",
              "question": "たべる → ___",
              "answer": "たべて"
            },
            {
              "type": "match",
              "pairs": {
                "いく": "いって",
                "のむ": "のんで"
              }
            }
          ]
        },
        {
          "id": "lesson_2",
          "title": "Mẫu câu ～ています",
          "content": """
## ～ています

Diễn tả hành động đang diễn ra.
""",
          "test": [
            {
              "type": "choice",
              "question": "～ています dùng để diễn tả?",
              "options": ["quá khứ", "đang diễn ra", "tương lai"],
              "answer": "đang diễn ra"
            },
            {
              "type": "fill",
              "question": "べんきょう ___。",
              "answer": "しています"
            },
            {
              "type": "match",
              "pairs": {
                "たべています": "đang ăn",
                "よんでいます": "đang đọc"
              }
            }
          ]
        }
      ]
    },
    {
      "id": "level_4",
      "title": "Intermediate",
      "subtitle": "Đọc hiểu & nghe N3",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Đọc hiểu đoạn ngắn",
          "content": """
## Đọc hiểu

Đọc đoạn văn và trả lời câu hỏi.
""",
          "test": [
            {
              "type": "choice",
              "question": "Đoạn văn nói về chủ đề gì?",
              "options": ["Gia đình", "Công việc", "Du lịch"],
              "answer": "Công việc"
            },
            {
              "type": "fill",
              "question": "主人公は ___ です。",
              "answer": "会社員"
            },
            {
              "type": "match",
              "pairs": {
                "会社": "công ty",
                "仕事": "công việc"
              }
            }
          ]
        },
        {
          "id": "lesson_2",
          "title": "Nghe hiểu hội thoại",
          "content": """
## Nghe hiểu

Nghe đoạn hội thoại ngắn.
""",
          "test": [
            {
              "type": "choice",
              "question": "Hai người đang nói ở đâu?",
              "options": ["Nhà ga", "Trường học", "Cửa hàng"],
              "answer": "Nhà ga"
            },
            {
              "type": "fill",
              "question": "Điểm đến là ___。",
              "answer": "東京"
            },
            {
              "type": "match",
              "pairs": {
                "切符": "vé tàu",
                "駅": "nhà ga"
              }
            }
          ]
        }
      ]
    }
  ];

  for (final level in levels) {
    final levelRef = ja.collection("courses").doc(level["id"] as String);

    await levelRef.set({
      "title": level["title"],
      "subtitle": level["subtitle"],
    });

    for (final lesson in level["lessons"] as List) {
      await levelRef
          .collection("lessons")
          .doc(lesson["id"])
          .set({
        "title": lesson["title"],
        "content": lesson["content"],
        "test": lesson["test"],
      });
    }
  }

  debugPrint("🔥 FULL JAPANESE DATA SEEDED");
}


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await seedKoreanLevel4();
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
            "✅ Korean learning data seeded successfully\nCheck Firestore",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

Future<void> seedKoreanLevel4() async {
  final db = FirebaseFirestore.instance;

  final level4Ref = db
      .collection("languages")
      .doc("ko")
      .collection("courses")
      .doc("level_4");

  await level4Ref.set({
    "title": "Upper-Intermediate",
    "subtitle": "Ngữ pháp trung cấp – TOPIK II",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Nguyên nhân sâu ～아/어 가지고",
      "order": 1,
      "content": {
        "introduction":
            "～아/어 가지고 dùng để nêu nguyên nhân dẫn đến kết quả rõ ràng.",
        "outcome": [
          "Diễn tả nguyên nhân – kết quả",
          "Phân biệt với ～아서/어서"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "비가 와 가지고 길이 막혔어요",
                "vi": "Vì mưa nên đường bị kẹt"
              },
              {
                "kr": "돈이 없어 가지고 못 샀어요",
                "vi": "Vì không có tiền nên không mua được"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～아/어 가지고 dùng để?",
          "options": ["Nguyên nhân – kết quả", "So sánh", "Giả định"],
          "answer": "Nguyên nhân – kết quả"
        },
        {
          "type": "fill",
          "question": "비가 와___ 집에 있었어요",
          "answer": "가지고",
          "options": ["가지고", "지만", "려고", "때문에", "거나"]
        },
        {
          "type": "match",
          "pairs": {
            "비가 와 가지고": "vì mưa nên",
            "돈이 없어 가지고": "vì không có tiền",
            "시간이 없어 가지고": "vì không có thời gian",
            "아파 가지고": "vì bị ốm"
          }
        }
      ]
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Giả định ～(으)면",
      "order": 2,
      "content": {
        "introduction":
            "～(으)면 dùng để nói điều kiện hoặc giả định.",
        "outcome": [
          "Nói điều kiện",
          "Dự đoán kết quả"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "시간이 있으면 여행할 거예요",
                "vi": "Nếu có thời gian thì sẽ đi du lịch"
              },
              {
                "kr": "비가 오면 집에 있을 거예요",
                "vi": "Nếu mưa thì sẽ ở nhà"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～(으)면 dùng khi nào?",
          "options": ["Giả định", "Nguyên nhân", "Mục đích"],
          "answer": "Giả định"
        },
        {
          "type": "fill",
          "question": "돈이 있___ 사고 싶어요",
          "answer": "으면",
          "options": ["으면", "지만", "어서", "기 때문에", "거나"]
        },
        {
          "type": "match",
          "pairs": {
            "시간이 있으면": "nếu có thời gian",
            "비가 오면": "nếu trời mưa",
            "돈이 있으면": "nếu có tiền",
            "기회가 있으면": "nếu có cơ hội"
          }
        }
      ]
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Trái ngược mạnh ～는데도",
      "order": 3,
      "content": {
        "introduction":
            "～는데도 dùng khi kết quả trái với mong đợi.",
        "outcome": [
          "Diễn tả trái ngược mạnh",
          "So sánh với ～지만"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "비가 오는데도 나갔어요",
                "vi": "Mặc dù mưa nhưng vẫn ra ngoài"
              },
              {
                "kr": "아픈데도 회사에 갔어요",
                "vi": "Dù bị ốm nhưng vẫn đi làm"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～는데도 diễn tả?",
          "options": ["Trái ngược mong đợi", "Nguyên nhân", "Giả định"],
          "answer": "Trái ngược mong đợi"
        },
        {
          "type": "fill",
          "question": "아픈___ 출근했어요",
          "answer": "데도",
          "options": ["데도", "지만", "어서", "려고", "거나"]
        },
        {
          "type": "match",
          "pairs": {
            "비가 오는데도": "mặc dù mưa",
            "아픈데도": "mặc dù bị ốm",
            "바쁜데도": "mặc dù bận",
            "늦었는데도": "mặc dù trễ"
          }
        }
      ]
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Bị động ～아/어지다",
      "order": 4,
      "content": {
        "introduction":
            "～아/어지다 dùng để diễn tả trạng thái bị động.",
        "outcome": [
          "Hiểu câu bị động",
          "Dùng trong mô tả tình huống"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "문이 열어졌어요",
                "vi": "Cửa đã được mở"
              },
              {
                "kr": "문제가 해결됐어요",
                "vi": "Vấn đề đã được giải quyết"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～아/어지다 dùng để?",
          "options": ["Bị động", "Chủ động", "Giả định"],
          "answer": "Bị động"
        },
        {
          "type": "fill",
          "question": "닫다 → 닫___",
          "answer": "아지다",
          "options": ["아지다", "고 있다", "려고", "지만", "거나"]
        },
        {
          "type": "match",
          "pairs": {
            "열어지다": "được mở",
            "닫아지다": "được đóng",
            "깨지다": "bị vỡ",
            "결정되다": "được quyết định"
          }
        }
      ]
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Gián tiếp ～다고 하다",
      "order": 5,
      "content": {
        "introduction":
            "～다고 하다 dùng để tường thuật lời nói.",
        "outcome": [
          "Nói gián tiếp",
          "Báo lại thông tin"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "내일 온다고 했어요",
                "vi": "Anh ấy nói là ngày mai sẽ đến"
              },
              {
                "kr": "비가 온다고 들었어요",
                "vi": "Tôi nghe nói là trời mưa"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～다고 하다 dùng để?",
          "options": ["Gián tiếp", "Mục đích", "So sánh"],
          "answer": "Gián tiếp"
        },
        {
          "type": "fill",
          "question": "온___ 했어요",
          "answer": "다고",
          "options": ["다고", "지만", "려고", "어서", "거나"]
        },
        {
          "type": "match",
          "pairs": {
            "온다고 하다": "nói là sẽ đến",
            "비가 온다고 하다": "nói là trời mưa",
            "좋다고 하다": "nói là tốt",
            "바쁘다고 하다": "nói là bận"
          }
        }
      ]
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "So sánh nâng cao ～에 비해서",
      "order": 6,
      "content": {
        "introduction":
            "～에 비해서 dùng để so sánh nâng cao.",
        "outcome": ["So sánh học thuật"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "작년에 비해서 물가가 올랐어요",
                "vi": "So với năm ngoái, giá cả tăng"
              },
              {
                "kr": "예전에 비해서 많이 좋아졌어요",
                "vi": "So với trước đây thì tốt hơn nhiều"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～에 비해서 dùng để?",
          "options": ["So sánh", "Nguyên nhân", "Giả định"],
          "answer": "So sánh"
        },
        {
          "type": "fill",
          "question": "작년에 ___",
          "answer": "비해서",
          "options": ["비해서", "때문에", "려고", "지만", "거나"]
        },
        {
          "type": "match",
          "pairs": {
            "작년에 비해서": "so với năm ngoái",
            "예전에 비해서": "so với trước đây",
            "다른 나라에 비해서": "so với nước khác",
            "과거에 비해서": "so với quá khứ"
          }
        }
      ]
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "Xu hướng ～아/어 가다",
      "order": 7,
      "content": {
        "introduction":
            "～아/어 가다 dùng để diễn tả sự thay đổi theo thời gian.",
        "outcome": ["Diễn tả xu hướng"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "날씨가 따뜻해 가요",
                "vi": "Thời tiết đang ấm dần"
              },
              {
                "kr": "한국어 실력이 늘어 가요",
                "vi": "Trình độ tiếng Hàn đang tăng"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～아/어 가다 dùng để?",
          "options": ["Xu hướng", "Kết quả", "Giả định"],
          "answer": "Xu hướng"
        },
        {
          "type": "fill",
          "question": "늘어 ___",
          "answer": "가요",
          "options": ["가요", "봐요", "두세요", "보세요", "주세요"]
        },
        {
          "type": "match",
          "pairs": {
            "따뜻해 가다": "ấm dần",
            "늘어 가다": "tăng dần",
            "변해 가다": "thay đổi dần",
            "좋아져 가다": "tốt lên dần"
          }
        }
      ]
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Mức độ ～만큼",
      "order": 8,
      "content": {
        "introduction":
            "～만큼 dùng để diễn tả mức độ tương đương.",
        "outcome": ["So sánh mức độ"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "생각한 만큼 어렵지 않아요",
                "vi": "Không khó như đã nghĩ"
              },
              {
                "kr": "노력한 만큼 결과가 나왔어요",
                "vi": "Kết quả xứng đáng với nỗ lực"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～만큼 dùng để?",
          "options": ["Mức độ", "Nguyên nhân", "Giả định"],
          "answer": "Mức độ"
        },
        {
          "type": "fill",
          "question": "기대한 ___",
          "answer": "만큼",
          "options": ["만큼", "기 때문에", "지만", "거나", "려고"]
        },
        {
          "type": "match",
          "pairs": {
            "생각한 만큼": "như đã nghĩ",
            "노력한 만큼": "tương xứng nỗ lực",
            "기대한 만큼": "như kỳ vọng",
            "원한 만큼": "như mong muốn"
          }
        }
      ]
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Thói quen ～곤 하다",
      "order": 9,
      "content": {
        "introduction":
            "～곤 하다 dùng để nói thói quen trong quá khứ.",
        "outcome": ["Nói thói quen"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "어릴 때 자주 놀곤 했어요",
                "vi": "Hồi nhỏ hay chơi"
              },
              {
                "kr": "주말마다 운동하곤 했어요",
                "vi": "Cuối tuần thường tập thể dục"
              }
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～곤 하다 dùng để?",
          "options": ["Thói quen", "Giả định", "So sánh"],
          "answer": "Thói quen"
        },
        {
          "type": "fill",
          "question": "자주 먹___ 했어요",
          "answer": "곤",
          "options": ["곤", "고", "지만", "아서", "려고"]
        },
        {
          "type": "match",
          "pairs": {
            "먹곤 하다": "thường ăn",
            "가곤 하다": "thường đi",
            "보곤 하다": "thường xem",
            "만나곤 하다": "thường gặp"
          }
        }
      ]
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập tổng hợp Level 4",
      "order": 10,
      "content": {
        "introduction":
            "Ôn tập toàn bộ ngữ pháp Level 4 – chuẩn bị học TOPIK II nâng cao.",
        "outcome": [
          "Củng cố ngữ pháp",
          "Nâng cao đọc – viết"
        ],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"kr": "아픈데도", "vi": "mặc dù bị ốm"},
              {"kr": "비교해서", "vi": "so sánh"},
              {"kr": "늘어 가다", "vi": "tăng dần"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "～는데도 dùng khi?",
          "options": ["Kết quả trái mong đợi", "Nguyên nhân", "Giả định"],
          "answer": "Kết quả trái mong đợi"
        },
        {
          "type": "fill",
          "question": "노력한 ___ 결과가 있어요",
          "answer": "만큼",
          "options": ["만큼", "기 때문에", "지만", "거나", "려고"]
        },
        {
          "type": "match",
          "pairs": {
            "아/어 가지고": "vì … nên",
            "는데도": "mặc dù",
            "비해서": "so với",
            "곤 하다": "thường hay"
          }
        }
      ]
    }
  };

  for (final entry in lessons.entries) {
    await level4Ref
        .collection("lessons")
        .doc(entry.key)
        .set(entry.value, SetOptions(merge: true));
  }

  debugPrint("🔥 DONE: Korean Level 4 – FULL, MATCH ≥ 4, TOPIK II");
}


Future<void> seedKoreanLevel3() async {
  final db = FirebaseFirestore.instance;

  final level3Ref = db
      .collection("languages")
      .doc("ko")
      .collection("courses")
      .doc("level_3");

  await level3Ref.set({
    "title": "Intermediate",
    "subtitle": "Ngữ pháp mở rộng – hội thoại – TOPIK I+",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Liên kết hành động ～고",
      "order": 1,
      "content": {
        "introduction":
            "Dùng ～고 để nối nhiều hành động hoặc trạng thái xảy ra liên tiếp.",
        "outcome": ["Nối câu đơn giản", "Diễn tả nhiều hành động"],
        "sections": [
          {
            "type": "grammar",
            "title": "Cấu trúc",
            "items": [
              {
                "kr": "밥을 먹고 학교에 가요",
                "romaji": "babeul meokgo hakgyoe gayo",
                "vi": "Ăn cơm rồi đi học",
              },
              {
                "kr": "책을 읽고 음악을 들어요",
                "romaji": "chaegeul ilkgo eumageul deureoyo",
                "vi": "Đọc sách và nghe nhạc",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～고 dùng để?",
          "options": ["Nối hành động", "Nêu lý do", "So sánh"],
          "answer": "Nối hành động",
        },
        {
          "type": "fill",
          "question": "밥을 먹다 ___ 학교에 가요",
          "answer": "고",
          "options": ["고", "아서", "지만", "때문에", "거나"],
        },
        {
          "type": "match",
          "pairs": {"먹고": "ăn rồi", "읽고": "đọc rồi"},
        },
      ],
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Đối lập ～지만",
      "order": 2,
      "content": {
        "introduction": "～지만 dùng để diễn tả hai ý trái ngược nhau.",
        "outcome": ["Nói câu đối lập", "Diễn tả tương phản"],
        "sections": [
          {
            "type": "grammar",
            "title": "Cấu trúc",
            "items": [
              {
                "kr": "비가 오지만 학교에 가요",
                "romaji": "",
                "vi": "Trời mưa nhưng vẫn đi học",
              },
              {"kr": "비싸지만 맛있어요", "romaji": "", "vi": "Đắt nhưng ngon"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～지만 dùng khi nào?",
          "options": ["Đối lập", "Lý do", "Mục đích"],
          "answer": "Đối lập",
        },
        {
          "type": "fill",
          "question": "맛있다 ___ 비싸요",
          "answer": "지만",
          "options": ["지만", "고", "아서", "거나", "때"],
        },
        {
          "type": "match",
          "pairs": {"비싸지만": "đắt nhưng", "춥지만": "lạnh nhưng"},
        },
      ],
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Nguyên nhân ～기 때문에",
      "order": 3,
      "content": {
        "introduction":
            "～기 때문에 dùng để nêu lý do rõ ràng, trang trọng hơn ～아서/어서.",
        "outcome": ["Nêu nguyên nhân rõ ràng"],
        "sections": [
          {
            "type": "grammar",
            "title": "Cấu trúc",
            "items": [
              {
                "kr": "비가 오기 때문에 집에 있어요",
                "romaji": "",
                "vi": "Vì trời mưa nên ở nhà",
              },
              {
                "kr": "바쁘기 때문에 못 가요",
                "romaji": "",
                "vi": "Vì bận nên không đi được",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～기 때문에 dùng để?",
          "options": ["Nêu lý do", "So sánh", "Mong muốn"],
          "answer": "Nêu lý do",
        },
        {
          "type": "fill",
          "question": "바쁘다 ___ 못 가요",
          "answer": "기 때문에",
          "options": ["기 때문에", "지만", "고", "거나", "아/어서"],
        },
        {
          "type": "match",
          "pairs": {"비가 오기 때문에": "vì mưa", "바쁘기 때문에": "vì bận"},
        },
      ],
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Thời điểm ～(으)ㄹ 때",
      "order": 4,
      "content": {
        "introduction":
            "～(으)ㄹ 때 dùng để nói về thời điểm một hành động xảy ra.",
        "outcome": ["Nói thời gian xảy ra"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "집에 갈 때 전화해요",
                "romaji": "",
                "vi": "Khi về nhà thì gọi điện",
              },
              {
                "kr": "밥을 먹을 때 TV를 봐요",
                "romaji": "",
                "vi": "Khi ăn cơm thì xem TV",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～(으)ㄹ 때 dùng để?",
          "options": ["Thời điểm", "Lý do", "Đối lập"],
          "answer": "Thời điểm",
        },
        {
          "type": "fill",
          "question": "집에 갈 ___ 전화해요",
          "answer": "때",
          "options": ["때", "고", "지만", "아서", "거나"],
        },
        {
          "type": "match",
          "pairs": {"갈 때": "khi đi", "먹을 때": "khi ăn"},
        },
      ],
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Lựa chọn ～거나",
      "order": 5,
      "content": {
        "introduction": "～거나 dùng để diễn tả lựa chọn A hoặc B.",
        "outcome": ["Nói lựa chọn"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "집에 있거나 친구를 만나요",
                "romaji": "",
                "vi": "Ở nhà hoặc gặp bạn",
              },
              {
                "kr": "커피를 마시거나 차를 마셔요",
                "romaji": "",
                "vi": "Uống cà phê hoặc uống trà",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～거나 dùng để?",
          "options": ["Lựa chọn", "Nguyên nhân", "So sánh"],
          "answer": "Lựa chọn",
        },
        {
          "type": "fill",
          "question": "먹___ 마셔요",
          "answer": "거나",
          "options": ["거나", "고", "지만", "아서", "때"],
        },
        {
          "type": "match",
          "pairs": {"있거나": "ở hoặc", "마시거나": "uống hoặc"},
        },
      ],
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Mục đích ～(으)려고",
      "order": 6,
      "content": {
        "introduction": "～(으)려고 dùng để nói mục đích của hành động.",
        "outcome": ["Nêu mục đích"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "한국어를 배우려고 한국에 왔어요",
                "romaji": "",
                "vi": "Đến Hàn để học tiếng Hàn",
              },
              {
                "kr": "운동하려고 헬스장에 가요",
                "romaji": "",
                "vi": "Đi phòng gym để tập thể dục",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～(으)려고 dùng để?",
          "options": ["Mục đích", "Lý do", "So sánh"],
          "answer": "Mục đích",
        },
        {
          "type": "fill",
          "question": "공부하___ 도서관에 가요",
          "answer": "려고",
          "options": ["려고", "고", "지만", "아서", "거나"],
        },
        {
          "type": "match",
          "pairs": {"배우려고": "để học", "운동하려고": "để tập"},
        },
      ],
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "Trải nghiệm ～아/어 본 적이 있어요",
      "order": 7,
      "content": {
        "introduction": "Diễn tả đã từng có trải nghiệm hay chưa.",
        "outcome": ["Nói kinh nghiệm"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "kr": "한국 음식을 먹어 본 적이 있어요",
                "romaji": "",
                "vi": "Đã từng ăn món Hàn",
              },
              {
                "kr": "한국에 가 본 적이 없어요",
                "romaji": "",
                "vi": "Chưa từng đi Hàn Quốc",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～본 적이 있어요 dùng khi?",
          "options": ["Nói trải nghiệm", "Mục đích", "So sánh"],
          "answer": "Nói trải nghiệm",
        },
        {
          "type": "fill",
          "question": "먹어 ___ 적이 있어요",
          "answer": "본",
          "options": ["본", "고", "지만", "려고", "때"],
        },
        {
          "type": "match",
          "pairs": {"가 본 적이 있어요": "đã từng đi", "먹어 본 적이 없어요": "chưa từng ăn"},
        },
      ],
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Trạng thái ～아/어 두다",
      "order": 8,
      "content": {
        "introduction":
            "～아/어 두다 dùng để nói hành động được làm sẵn cho tương lai.",
        "outcome": ["Nói hành động chuẩn bị trước"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"kr": "문을 열어 두세요", "romaji": "", "vi": "Hãy mở sẵn cửa"},
              {"kr": "음식을 만들어 두었어요", "romaji": "", "vi": "Đã nấu sẵn đồ ăn"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～아/어 두다 dùng để?",
          "options": ["Chuẩn bị sẵn", "So sánh", "Đối lập"],
          "answer": "Chuẩn bị sẵn",
        },
        {
          "type": "fill",
          "question": "열어 ___",
          "answer": "두세요",
          "options": ["두세요", "보세요", "주세요", "있어요", "가세요"],
        },
        {
          "type": "match",
          "pairs": {"열어 두다": "mở sẵn", "만들어 두다": "làm sẵn"},
        },
      ],
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Dự đoán ～(으)ㄹ 것 같아요",
      "order": 9,
      "content": {
        "introduction": "Diễn tả suy đoán, cảm nhận cá nhân.",
        "outcome": ["Nói dự đoán"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"kr": "비가 올 것 같아요", "romaji": "", "vi": "Có vẻ sẽ mưa"},
              {
                "kr": "이 음식이 맛있을 것 같아요",
                "romaji": "",
                "vi": "Món này có vẻ ngon",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～것 같아요 dùng để?",
          "options": ["Dự đoán", "Mệnh lệnh", "So sánh"],
          "answer": "Dự đoán",
        },
        {
          "type": "fill",
          "question": "비가 올 ___",
          "answer": "것 같아요",
          "options": ["것 같아요", "려고", "때문에", "거나", "지만"],
        },
        {
          "type": "match",
          "pairs": {"올 것 같아요": "có vẻ sẽ đến", "맛있을 것 같아요": "có vẻ ngon"},
        },
      ],
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập tổng hợp Level 3",
      "order": 10,
      "content": {
        "introduction":
            "Tổng hợp toàn bộ ngữ pháp Level 3 – chuẩn bị lên TOPIK II.",
        "outcome": [
          "Củng cố ngữ pháp trung cấp",
          "Nâng cao khả năng đọc – nói",
        ],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"kr": "먹고", "romaji": "", "vi": "ăn rồi"},
              {"kr": "먹지만", "romaji": "", "vi": "ăn nhưng"},
              {"kr": "먹으려고", "romaji": "", "vi": "để ăn"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～(으)려고 dùng để?",
          "options": ["Mục đích", "Đối lập", "So sánh"],
          "answer": "Mục đích",
        },
        {
          "type": "fill",
          "question": "공부하___ 한국에 왔어요",
          "answer": "려고",
          "options": ["려고", "지만", "고", "때", "거나"],
        },
        {
          "type": "match",
          "pairs": {"기 때문에": "vì", "것 같아요": "có vẻ"},
        },
      ],
    },
  };

  for (final entry in lessons.entries) {
    await level3Ref
        .collection("lessons")
        .doc(entry.key)
        .set(entry.value, SetOptions(merge: true));
  }

  debugPrint("🔥 DONE: Korean Level 3 – FULL, DÀI, CHUẨN TOPIK");
}

Future<void> seedKoreanLevel2() async {
  final db = FirebaseFirestore.instance;

  final level2Ref = db
      .collection("languages")
      .doc("ko")
      .collection("courses")
      .doc("level_2");

  await level2Ref.set({
    "title": "Beginner Plus",
    "subtitle": "Ngữ pháp cơ bản – hội thoại – TOPIK I",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Hiện tại đuôi ～아요 / ～어요",
      "order": 1,
      "content": {
        "introduction": "Cách chia động từ hiện tại lịch sự.",
        "outcome": ["Chia động từ hiện tại", "Dùng trong hội thoại hàng ngày"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"kr": "먹어요", "romaji": "meogeoyo", "vi": "ăn"},
              {"kr": "가요", "romaji": "gayo", "vi": "đi"},
              {"kr": "봐요", "romaji": "bwayo", "vi": "xem"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "먹다 → ?",
          "options": ["먹어요", "먹었어요", "먹을 거예요"],
          "answer": "먹어요",
        },
        {
          "type": "fill",
          "question": "가다 → ___",
          "answer": "가요",
          "options": ["가요", "갔어요", "갈 거예요", "가세요", "가지 마세요"],
        },
        {
          "type": "match",
          "pairs": {"먹어요": "ăn", "가요": "đi", "봐요": "xem"},
        },
      ],
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Quá khứ ～았어요 / ～었어요",
      "order": 2,
      "content": {
        "introduction": "Diễn tả hành động đã xảy ra.",
        "outcome": ["Nói việc đã làm"],
        "sections": [
          {
            "type": "grammar",
            "title": "Quá khứ",
            "items": [
              {"kr": "먹었어요", "romaji": "meogeosseoyo", "vi": "đã ăn"},
              {"kr": "갔어요", "romaji": "gasseoyo", "vi": "đã đi"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "가다 → quá khứ?",
          "options": ["갔어요", "가요", "갈 거예요"],
          "answer": "갔어요",
        },
        {
          "type": "fill",
          "question": "먹다 → ___",
          "answer": "먹었어요",
          "options": ["먹었어요", "먹어요", "먹을 거예요", "먹지 않아요", "먹으세요"],
        },
        {
          "type": "match",
          "pairs": {"먹었어요": "đã ăn", "갔어요": "đã đi"},
        },
      ],
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Phủ định ～지 않아요",
      "order": 3,
      "content": {
        "introduction": "Cách nói không làm gì.",
        "outcome": ["Nói câu phủ định"],
        "sections": [
          {
            "type": "grammar",
            "title": "Phủ định",
            "items": [
              {"kr": "먹지 않아요", "romaji": "meokji anayo", "vi": "không ăn"},
              {"kr": "가지 않아요", "romaji": "gaji anayo", "vi": "không đi"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Phủ định của 가요?",
          "options": ["가지 않아요", "갔어요", "갈 거예요"],
          "answer": "가지 않아요",
        },
        {
          "type": "fill",
          "question": "먹다 → ___",
          "answer": "먹지 않아요",
          "options": ["먹지 않아요", "먹어요", "먹었어요", "먹을 거예요", "먹으세요"],
        },
        {
          "type": "match",
          "pairs": {"먹지 않아요": "không ăn", "가지 않아요": "không đi"},
        },
      ],
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Mong muốn ～고 싶어요",
      "order": 4,
      "content": {
        "introduction": "Diễn tả mong muốn.",
        "outcome": ["Nói muốn làm gì"],
        "sections": [
          {
            "type": "grammar",
            "title": "Muốn",
            "items": [
              {"kr": "먹고 싶어요", "romaji": "meokgo sipeoyo", "vi": "muốn ăn"},
              {"kr": "가고 싶어요", "romaji": "gago sipeoyo", "vi": "muốn đi"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "가고 싶어요 nghĩa là?",
          "options": ["Muốn đi", "Đã đi", "Không đi"],
          "answer": "Muốn đi",
        },
        {
          "type": "fill",
          "question": "먹다 → ___",
          "answer": "먹고 싶어요",
          "options": ["먹고 싶어요", "먹어요", "먹었어요", "먹지 않아요", "먹으세요"],
        },
        {
          "type": "match",
          "pairs": {"먹고 싶어요": "muốn ăn", "가고 싶어요": "muốn đi"},
        },
      ],
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Lý do ～아/어서",
      "order": 5,
      "content": {
        "introduction": "Nêu lý do.",
        "outcome": ["Nói nguyên nhân"],
        "sections": [
          {
            "type": "grammar",
            "title": "아서/어서",
            "items": [
              {"kr": "비가 와서", "romaji": "biga waseo", "vi": "vì mưa"},
              {"kr": "바빠서", "romaji": "bappaseo", "vi": "vì bận"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～아서/어서 dùng để?",
          "options": ["Nêu lý do", "Mong muốn", "So sánh"],
          "answer": "Nêu lý do",
        },
        {
          "type": "fill",
          "question": "바쁘다 → ___",
          "answer": "바빠서",
          "options": ["바빠서", "바빠요", "바빴어요", "바쁘지 않아요", "바쁠 거예요"],
        },
        {
          "type": "match",
          "pairs": {"비가 와서": "vì mưa", "바빠서": "vì bận"},
        },
      ],
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Đề nghị ～(으)세요",
      "order": 6,
      "content": {
        "introduction": "Cách đề nghị lịch sự.",
        "outcome": ["Đưa ra đề nghị"],
        "sections": [
          {
            "type": "grammar",
            "title": "Đề nghị",
            "items": [
              {"kr": "드세요", "romaji": "deuseyo", "vi": "xin mời ăn"},
              {"kr": "오세요", "romaji": "oseyo", "vi": "hãy đến"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "드세요 nghĩa là?",
          "options": ["Xin mời ăn", "Muốn ăn", "Không ăn"],
          "answer": "Xin mời ăn",
        },
        {
          "type": "fill",
          "question": "오다 → ___",
          "answer": "오세요",
          "options": ["오세요", "와요", "왔어요", "오고 싶어요", "오지 않아요"],
        },
        {
          "type": "match",
          "pairs": {"드세요": "xin mời ăn", "오세요": "hãy đến"},
        },
      ],
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "Khả năng ～(으)ㄹ 수 있어요",
      "order": 7,
      "content": {
        "introduction": "Diễn tả khả năng.",
        "outcome": ["Nói có thể làm gì"],
        "sections": [
          {
            "type": "grammar",
            "title": "Khả năng",
            "items": [
              {"kr": "할 수 있어요", "romaji": "hal su isseoyo", "vi": "có thể làm"},
              {
                "kr": "읽을 수 있어요",
                "romaji": "ilkeul su isseoyo",
                "vi": "có thể đọc",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "할 수 있어요 nghĩa là?",
          "options": ["Có thể làm", "Muốn làm", "Đã làm"],
          "answer": "Có thể làm",
        },
        {
          "type": "fill",
          "question": "읽다 → ___",
          "answer": "읽을 수 있어요",
          "options": ["읽을 수 있어요", "읽어요", "읽었어요", "읽고 싶어요", "읽지 않아요"],
        },
        {
          "type": "match",
          "pairs": {"할 수 있어요": "có thể làm", "읽을 수 있어요": "có thể đọc"},
        },
      ],
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Tương lai ～(으)ㄹ 거예요",
      "order": 8,
      "content": {
        "introduction": "Nói về kế hoạch tương lai.",
        "outcome": ["Diễn tả tương lai"],
        "sections": [
          {
            "type": "grammar",
            "title": "Tương lai",
            "items": [
              {"kr": "갈 거예요", "romaji": "gal geoyeyo", "vi": "sẽ đi"},
              {"kr": "먹을 거예요", "romaji": "meogeul geoyeyo", "vi": "sẽ ăn"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "갈 거예요 nghĩa là?",
          "options": ["Sẽ đi", "Đã đi", "Không đi"],
          "answer": "Sẽ đi",
        },
        {
          "type": "fill",
          "question": "먹다 → ___",
          "answer": "먹을 거예요",
          "options": ["먹을 거예요", "먹어요", "먹었어요", "먹지 않아요", "먹고 싶어요"],
        },
        {
          "type": "match",
          "pairs": {"갈 거예요": "sẽ đi", "먹을 거예요": "sẽ ăn"},
        },
      ],
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "So sánh ～보다",
      "order": 9,
      "content": {
        "introduction": "So sánh hai đối tượng.",
        "outcome": ["So sánh hơn"],
        "sections": [
          {
            "type": "grammar",
            "title": "So sánh",
            "items": [
              {
                "kr": "한국이 베트남보다 커요",
                "romaji": "",
                "vi": "Hàn Quốc lớn hơn Việt Nam",
              },
              {"kr": "이게 더 좋아요", "romaji": "", "vi": "Cái này tốt hơn"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "～보다 dùng để?",
          "options": ["So sánh", "Lý do", "Mong muốn"],
          "answer": "So sánh",
        },
        {
          "type": "fill",
          "question": "A ___ B",
          "answer": "보다",
          "options": ["보다", "에서", "에게", "하고", "까지"],
        },
        {
          "type": "match",
          "pairs": {"보다": "so với", "더": "hơn"},
        },
      ],
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập Level 2",
      "order": 10,
      "content": {
        "introduction": "Tổng hợp toàn bộ ngữ pháp Level 2.",
        "outcome": ["Củng cố TOPIK I"],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"kr": "먹어요", "romaji": "", "vi": "ăn"},
              {"kr": "먹었어요", "romaji": "", "vi": "đã ăn"},
              {"kr": "먹고 싶어요", "romaji": "", "vi": "muốn ăn"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "먹고 싶어요 nghĩa là?",
          "options": ["Muốn ăn", "Đã ăn", "Không ăn"],
          "answer": "Muốn ăn",
        },
        {
          "type": "fill",
          "question": "가다 → tương lai?",
          "answer": "갈 거예요",
          "options": ["갈 거예요", "가요", "갔어요", "가지 않아요", "가고 싶어요"],
        },
        {
          "type": "match",
          "pairs": {"먹어요": "ăn", "먹었어요": "đã ăn", "먹고 싶어요": "muốn ăn"},
        },
      ],
    },
  };

  for (final entry in lessons.entries) {
    await level2Ref
        .collection("lessons")
        .doc(entry.key)
        .set(entry.value, SetOptions(merge: true));
  }

  debugPrint("🔥 DONE: Korean Level 2 10 lessons, FULL & CHUẨN");
}

/// =======================================================
/// MIGRATE fill → choice (KOREAN)
/// =======================================================
Future<void> migrateFillQuestionsToChoiceKo() async {
  final db = FirebaseFirestore.instance;

  final lessonsRef = db
      .collection("languages")
      .doc("ko")
      .collection("courses")
      .doc("level_1")
      .collection("lessons");

  final snapshot = await lessonsRef.get();

  final distractors = ["나", "너", "그", "그녀", "사람", "이것", "그것", "저것", "여기", "거기"];

  for (final lesson in snapshot.docs) {
    final data = lesson.data();
    if (!data.containsKey("test")) continue;

    final List tests = List.from(data["test"]);
    bool updated = false;

    final newTests = tests.map((q) {
      if (q["type"] == "fill" && q["options"] == null) {
        final String answer = q["answer"];
        final options = <String>{answer};

        for (final d in distractors) {
          if (options.length >= 5) break;
          if (d != answer) options.add(d);
        }

        updated = true;

        return {...q, "options": options.toList()..shuffle()};
      }
      return q;
    }).toList();

    if (updated) {
      await lesson.reference.update({"test": newTests});
      debugPrint("✅ Migrated fill → choice in ${lesson.id}");
    }
  }

  debugPrint("🔥 DONE: All Korean fill questions converted");
}

Future<void> updateLesson2To10ContentKo() async {
  final db = FirebaseFirestore.instance;

  final lessons = {
    "lesson_2": {
      "introduction":
          "Học các câu chào hỏi cơ bản trong giao tiếp hằng ngày bằng tiếng Hàn.",
      "outcome": ["Biết cách chào hỏi lịch sự", "Phản xạ chào hỏi tự nhiên"],
      "sections": [
        {
          "type": "sentence",
          "title": "Câu chào hỏi",
          "items": [
            {"jp": "안녕하세요", "romaji": "annyeonghaseyo", "vi": "Xin chào"},
            {"jp": "감사합니다", "romaji": "gamsahamnida", "vi": "Cảm ơn"},
            {"jp": "안녕히 가세요", "romaji": "annyeonghi gaseyo", "vi": "Tạm biệt"},
          ],
        },
      ],
    },

    "lesson_3": {
      "introduction": "Học cách giới thiệu bản thân bằng tiếng Hàn.",
      "outcome": ["Biết giới thiệu tên", "Hiểu cấu trúc câu 입니다"],
      "sections": [
        {
          "type": "sentence",
          "title": "Giới thiệu bản thân",
          "items": [
            {
              "jp": "저는 안입니다.",
              "romaji": "jeoneun An imnida",
              "vi": "Tôi là An",
            },
            {
              "jp": "만나서 반갑습니다.",
              "romaji": "mannaseo bangapseumnida",
              "vi": "Rất vui được gặp bạn",
            },
          ],
        },
      ],
    },

    "lesson_4": {
      "introduction": "Làm quen với số đếm từ 1 đến 5 trong tiếng Hàn.",
      "outcome": ["Nhớ số cơ bản", "Ứng dụng vào tuổi và số lượng"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Số đếm",
          "items": [
            {"jp": "하나", "romaji": "hana", "vi": "1"},
            {"jp": "둘", "romaji": "dul", "vi": "2"},
            {"jp": "셋", "romaji": "set", "vi": "3"},
            {"jp": "넷", "romaji": "net", "vi": "4"},
            {"jp": "다섯", "romaji": "daseot", "vi": "5"},
          ],
        },
      ],
    },

    "lesson_5": {
      "introduction": "Từ vựng các đồ vật quen thuộc trong tiếng Hàn.",
      "outcome": ["Gọi tên đồ vật xung quanh", "Mở rộng vốn từ"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Đồ vật",
          "items": [
            {"jp": "책", "romaji": "chaek", "vi": "Sách"},
            {"jp": "펜", "romaji": "pen", "vi": "Bút"},
            {"jp": "가방", "romaji": "gabang", "vi": "Cặp"},
          ],
        },
      ],
    },

    "lesson_6": {
      "introduction":
          "Học cách nói câu khẳng định và phủ định trong tiếng Hàn.",
      "outcome": ["Nói câu khẳng định", "Nói câu phủ định"],
      "sections": [
        {
          "type": "grammar",
          "title": "Cấu trúc câu",
          "items": [
            {"jp": "입니다", "romaji": "imnida", "vi": "là"},
            {"jp": "아닙니다", "romaji": "animnida", "vi": "không phải"},
          ],
        },
      ],
    },

    "lesson_7": {
      "introduction": "Học từ vựng về gia đình trong tiếng Hàn.",
      "outcome": ["Giới thiệu gia đình", "Nhận biết từ xưng hô"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Gia đình",
          "items": [
            {"jp": "아버지", "romaji": "abeoji", "vi": "Bố"},
            {"jp": "어머니", "romaji": "eomeoni", "vi": "Mẹ"},
            {"jp": "형", "romaji": "hyeong", "vi": "Anh trai"},
          ],
        },
      ],
    },

    "lesson_8": {
      "introduction": "Các từ chỉ thời gian thường dùng trong tiếng Hàn.",
      "outcome": ["Nói về thời gian", "Hiểu ngữ cảnh câu"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Thời gian",
          "items": [
            {"jp": "오늘", "romaji": "oneul", "vi": "Hôm nay"},
            {"jp": "내일", "romaji": "naeil", "vi": "Ngày mai"},
            {"jp": "지금", "romaji": "jigeum", "vi": "Bây giờ"},
          ],
        },
      ],
    },

    "lesson_9": {
      "introduction": "Các động từ cơ bản trong sinh hoạt hằng ngày.",
      "outcome": ["Nhận biết động từ", "Sử dụng trong câu đơn"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Động từ",
          "items": [
            {"jp": "먹습니다", "romaji": "meokseumnida", "vi": "Ăn"},
            {"jp": "마십니다", "romaji": "masimnida", "vi": "Uống"},
            {"jp": "갑니다", "romaji": "gamnida", "vi": "Đi"},
          ],
        },
      ],
    },

    "lesson_10": {
      "introduction": "Hội thoại chào hỏi và hỏi tên bằng tiếng Hàn.",
      "outcome": ["Thực hành hội thoại", "Phản xạ giao tiếp"],
      "sections": [
        {
          "type": "sentence",
          "title": "Hội thoại",
          "items": [
            {"jp": "안녕하세요", "romaji": "annyeonghaseyo", "vi": "Xin chào"},
            {
              "jp": "이름이 뭐예요?",
              "romaji": "ireumi mwoyeyo?",
              "vi": "Tên bạn là gì?",
            },
            {"jp": "안입니다.", "romaji": "An imnida", "vi": "Tôi là An"},
          ],
        },
      ],
    },
  };

  for (final entry in lessons.entries) {
    await db
        .collection("languages")
        .doc("ko")
        .collection("courses")
        .doc("level_1")
        .collection("lessons")
        .doc(entry.key)
        .update({"content": entry.value});

    debugPrint("✅ Updated ${entry.key} (Korean)");
  }

  debugPrint("🔥 ALL Korean lesson 2 → 10 UPDATED");
}

Future<void> updateLesson1ContentKo() async {
  final db = FirebaseFirestore.instance;

  final lessonRef = db
      .collection("languages")
      .doc("ko")
      .collection("courses")
      .doc("level_1")
      .collection("lessons")
      .doc("lesson_1");

  final newContent = {
    "introduction":
        "Trong bài học này, bạn sẽ làm quen với 5 nguyên âm cơ bản đầu tiên trong bảng chữ cái Hangeul của tiếng Hàn.",
    "outcome": [
      "Nhận biết và đọc đúng ㅏ・ㅓ・ㅗ・ㅜ・ㅣ",
      "Phát âm chuẩn tiếng Hàn",
      "Biết cách ghép chữ đơn giản",
    ],
    "sections": [
      {
        "type": "phonetic",
        "title": "Ngữ âm Hangeul",
        "items": [
          {
            "jp": "ㅏ",
            "romaji": "a",
            "vi": "a",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/%E3%85%8F_%28a%29_stroke_order.png/250px-%E3%85%8F_%28a%29_stroke_order.png",
          },
          {
            "jp": "ㅓ",
            "romaji": "eo",
            "vi": "ơ",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/%E3%85%93_%28eo%29_stroke_order.png/219px-%E3%85%93_%28eo%29_stroke_order.png",
          },
          {
            "jp": "ㅗ",
            "romaji": "o",
            "vi": "o",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/%E3%85%97_%28o%29_stroke_order-2.png/250px-%E3%85%97_%28o%29_stroke_order-2.png",
          },
          {
            "jp": "ㅜ",
            "romaji": "u",
            "vi": "u",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c9/%E3%85%9C_%28u%29_stroke_order.png/250px-%E3%85%9C_%28u%29_stroke_order.png",
          },
          {
            "jp": "ㅣ",
            "romaji": "i",
            "vi": "i",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/%E3%85%A3_%28i%29_stroke_order.png/200px-%E3%85%A3_%28i%29_stroke_order.png",
          },
        ],
      },
      {
        "type": "example",
        "title": "Từ ghép đơn giản",
        "items": [
          {"jp": "아이", "romaji": "ai", "vi": "đứa trẻ"},
          {"jp": "우유", "romaji": "uyu", "vi": "sữa"},
        ],
      },
    ],
  };

  await lessonRef.update({"content": newContent});

  debugPrint("🔥 lesson_1 (Korean) content UPDATED");
}

Future<void> updateLessonOrderLevel1Ko() async {
  final db = FirebaseFirestore.instance;

  final lessonsRef = db
      .collection("languages")
      .doc("ko")
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

    await doc.reference.update({"order": order});

    debugPrint("✅ Updated $docId → order = $order");
  }

  debugPrint("🔥 DONE: order field added to all Korean lessons");
}

Future<void> addMoreLessonsLevel1Ko() async {
  final db = FirebaseFirestore.instance;

  final level1Lessons = db
      .collection("languages")
      .doc("ko")
      .collection("courses")
      .doc("level_1")
      .collection("lessons");

  final newLessons = [
    {
      "id": "lesson_3",
      "title": "Giới thiệu bản thân",
      "content": """
## 자기소개

- 나 : Tôi
- 이름 : Tên

Mẫu câu:
- 저는 안입니다.
""",
      "test": [
        {
          "type": "choice",
          "question": "Câu nào dùng để giới thiệu bản thân?",
          "options": ["감사합니다", "저는 안입니다", "안녕히 가세요"],
          "answer": "저는 안입니다",
        },
        {"type": "fill", "question": "___ 은 안입니다.", "answer": "저"},
        {
          "type": "match",
          "pairs": {"저": "Tôi", "이름": "Tên"},
        },
      ],
    },

    {
      "id": "lesson_4",
      "title": "Số đếm & tuổi",
      "content": """
## Số đếm

- 하나 : 1
- 둘 : 2
- 셋 : 3
- 넷 : 4
- 다섯 : 5
""",
      "test": [
        {
          "type": "choice",
          "question": "Số 4 đọc là?",
          "options": ["셋", "넷", "다섯"],
          "answer": "넷",
        },
        {"type": "fill", "question": "셋 = ___", "answer": "3"},
        {
          "type": "match",
          "pairs": {"하나": "1", "둘": "2", "셋": "3"},
        },
      ],
    },

    {
      "id": "lesson_5",
      "title": "Đồ vật quen thuộc",
      "content": """
## Đồ vật

- 책 : Sách
- 펜 : Bút
- 가방 : Cặp
""",
      "test": [
        {
          "type": "choice",
          "question": "책 là gì?",
          "options": ["Bút", "Sách", "Cặp"],
          "answer": "Sách",
        },
        {"type": "fill", "question": "펜 = ___", "answer": "Bút"},
        {
          "type": "match",
          "pairs": {"책": "Sách", "펜": "Bút", "가방": "Cặp"},
        },
      ],
    },

    {
      "id": "lesson_6",
      "title": "Câu khẳng định – phủ định",
      "content": """
## Khẳng định & phủ định

- 입니다 : là
- 아닙니다 : không phải
""",
      "test": [
        {
          "type": "choice",
          "question": "Câu phủ định là?",
          "options": ["입니다", "아닙니다", "합니다"],
          "answer": "아닙니다",
        },
        {"type": "fill", "question": "책 ___。", "answer": "아닙니다"},
        {
          "type": "match",
          "pairs": {"입니다": "là", "아닙니다": "không phải"},
        },
      ],
    },

    {
      "id": "lesson_7",
      "title": "Gia đình",
      "content": """
## Gia đình

- 아버지 : Bố
- 어머니 : Mẹ
- 형 : Anh trai
""",
      "test": [
        {
          "type": "choice",
          "question": "어머니 là ai?",
          "options": ["Bố", "Mẹ", "Anh"],
          "answer": "Mẹ",
        },
        {"type": "fill", "question": "___ 은 아버지입니다.", "answer": "그분"},
        {
          "type": "match",
          "pairs": {"아버지": "Bố", "어머니": "Mẹ", "형": "Anh trai"},
        },
      ],
    },

    {
      "id": "lesson_8",
      "title": "Thời gian – ngày tháng",
      "content": """
## Thời gian

- 오늘 : Hôm nay
- 내일 : Ngày mai
- 지금 : Bây giờ
""",
      "test": [
        {
          "type": "choice",
          "question": "오늘 nghĩa là?",
          "options": ["Hôm nay", "Ngày mai", "Hôm qua"],
          "answer": "Hôm nay",
        },
        {"type": "fill", "question": "지금 = ___", "answer": "Bây giờ"},
        {
          "type": "match",
          "pairs": {"오늘": "Hôm nay", "내일": "Ngày mai", "지금": "Bây giờ"},
        },
      ],
    },

    {
      "id": "lesson_9",
      "title": "Động từ cơ bản",
      "content": """
## Động từ

- 먹습니다 : Ăn
- 마십니다 : Uống
- 갑니다 : Đi
""",
      "test": [
        {
          "type": "choice",
          "question": "먹습니다 nghĩa là?",
          "options": ["Uống", "Ăn", "Đi"],
          "answer": "Ăn",
        },
        {"type": "fill", "question": "마십니다 = ___", "answer": "Uống"},
        {
          "type": "match",
          "pairs": {"먹습니다": "Ăn", "마십니다": "Uống", "갑니다": "Đi"},
        },
      ],
    },

    {
      "id": "lesson_10",
      "title": "Hội thoại đơn giản",
      "content": """
## Hội thoại

- A: 안녕하세요
- B: 안녕하세요
- A: 이름이 뭐예요?
- B: 안입니다.
""",
      "test": [
        {
          "type": "choice",
          "question": "이름이 뭐예요? nghĩa là?",
          "options": ["Xin chào", "Tên bạn là gì?", "Bạn khỏe không?"],
          "answer": "Tên bạn là gì?",
        },
        {"type": "fill", "question": "___ 입니다.", "answer": "안"},
        {
          "type": "match",
          "pairs": {"안녕하세요": "Xin chào", "이름": "Tên", "입니다": "là"},
        },
      ],
    },
  ];

  for (final lesson in newLessons) {
    await level1Lessons.doc(lesson["id"] as String).set({
      "title": lesson["title"],
      "content": lesson["content"],
      "test": lesson["test"],
    });
  }

  debugPrint("✅ Added lesson_3 → lesson_10 (Korean) to level_1");
}

/// =======================================================
/// SEED FULL KOREAN DATA
/// =======================================================
Future<void> seedKoreanData() async {
  final db = FirebaseFirestore.instance;
  final ko = db.collection("languages").doc("ko");

  await ko.set({"name": "Korean"});

  final levels = [
    {
      "id": "level_1",
      "title": "Beginner",
      "subtitle": "Bảng chữ & chào hỏi",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Hangeul cơ bản",
          "content": """
## Hangeul

### Nguyên âm cơ bản
- ㅏ (a)
- ㅓ (eo)
- ㅗ (o)
- ㅜ (u)
- ㅣ (i)

### Ví dụ
- 아이 (đứa trẻ)
- 우유 (sữa)
""",
          "test": [
            {
              "type": "choice",
              "question": "Chữ nào đọc là a?",
              "options": ["ㅓ", "ㅏ", "ㅜ"],
              "answer": "ㅏ",
            },
            {
              "type": "fill",
              "question": "Điền chữ đúng: ___ 이 (đứa trẻ)",
              "answer": "아",
            },
            {
              "type": "match",
              "pairs": {"ㅏ": "a", "ㅓ": "eo", "ㅣ": "i"},
            },
          ],
        },
        {
          "id": "lesson_2",
          "title": "Chào hỏi cơ bản",
          "content": """
## Chào hỏi

- 안녕하세요 : Xin chào
- 감사합니다 : Cảm ơn
- 안녕히 가세요 : Tạm biệt
""",
          "test": [
            {
              "type": "choice",
              "question": "Câu nào dùng để chào?",
              "options": ["감사합니다", "안녕하세요", "미안합니다"],
              "answer": "안녕하세요",
            },
            {"type": "fill", "question": "___ 합니다 = cảm ơn", "answer": "감사"},
            {
              "type": "match",
              "pairs": {
                "안녕하세요": "Xin chào",
                "감사합니다": "Cảm ơn",
                "안녕히 가세요": "Tạm biệt",
              },
            },
          ],
        },
      ],
    },
    {
      "id": "level_2",
      "title": "Elementary",
      "subtitle": "Từ vựng & ngữ pháp cơ bản",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Giới thiệu bản thân",
          "content": """
## Giới thiệu

- 저는 민수입니다.
- 만나서 반갑습니다.
""",
          "test": [
            {
              "type": "choice",
              "question": "Câu nào dùng để giới thiệu?",
              "options": ["안녕하세요", "저는 민수입니다", "감사합니다"],
              "answer": "저는 민수입니다",
            },
            {"type": "fill", "question": "___ 은 학생입니다.", "answer": "저"},
            {
              "type": "match",
              "pairs": {"저": "tôi", "학생": "học sinh", "이름": "tên"},
            },
          ],
        },
        {
          "id": "lesson_2",
          "title": "Số đếm 1–5",
          "content": """
## Số đếm

1 하나  
2 둘  
3 셋  
4 넷  
5 다섯  
""",
          "test": [
            {
              "type": "choice",
              "question": "Số 3 đọc là?",
              "options": ["둘", "셋", "넷"],
              "answer": "셋",
            },
            {"type": "fill", "question": "넷 = ___", "answer": "4"},
            {
              "type": "match",
              "pairs": {"하나": "1", "둘": "2", "셋": "3"},
            },
          ],
        },
      ],
    },
    {
      "id": "level_3",
      "title": "Pre-Intermediate",
      "subtitle": "Ngữ pháp trung cấp",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Thì hiện tại tiếp diễn",
          "content": """
## ~고 있다

Diễn tả hành động đang diễn ra.
""",
          "test": [
            {
              "type": "choice",
              "question": "~고 있다 dùng để?",
              "options": ["quá khứ", "đang diễn ra", "tương lai"],
              "answer": "đang diễn ra",
            },
            {"type": "fill", "question": "공부 ___ 있습니다.", "answer": "하고"},
            {
              "type": "match",
              "pairs": {"먹고 있다": "đang ăn", "읽고 있다": "đang đọc"},
            },
          ],
        },
      ],
    },
    {
      "id": "level_4",
      "title": "Intermediate",
      "subtitle": "Nghe & đọc hiểu",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Đọc hiểu",
          "content": """
## Đọc hiểu

Đọc đoạn văn và trả lời câu hỏi.
""",
          "test": [
            {
              "type": "choice",
              "question": "Đoạn văn nói về?",
              "options": ["Gia đình", "Công việc", "Du lịch"],
              "answer": "Công việc",
            },
            {"type": "fill", "question": "주인공은 ___ 입니다.", "answer": "회사원"},
            {
              "type": "match",
              "pairs": {"회사": "công ty", "일": "công việc"},
            },
          ],
        },
      ],
    },
  ];

  for (final level in levels) {
    final levelRef = ko.collection("courses").doc(level["id"] as String);

    await levelRef.set({
      "title": level["title"],
      "subtitle": level["subtitle"],
    });

    for (final lesson in level["lessons"] as List) {
      await levelRef.collection("lessons").doc(lesson["id"]).set({
        "title": lesson["title"],
        "content": lesson["content"],
        "test": lesson["test"],
      });
    }
  }

  debugPrint("🔥 FULL KOREAN DATA SEEDED");
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await seedChineseLevel4();

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
Future<void> seedChineseLevel4() async {
  final db = FirebaseFirestore.instance;

  final level4Ref = db
      .collection("languages")
      .doc("zh")
      .collection("courses")
      .doc("level_4");

  await level4Ref.set({
    "title": "Intermediate",
    "subtitle": "Ngữ pháp trung cấp – giao tiếp – HSK 4",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Mặc dù… nhưng… 虽然…但是…",
      "order": 1,
      "content": {
        "introduction":
            "虽然…但是… dùng để diễn tả sự tương phản mạnh giữa hai vế.",
        "outcome": [
          "Diễn tả đối lập",
          "Nói câu dài mạch lạc"
        ],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "虽然下雨，但是他还是来了", "vi": "Mặc dù mưa nhưng anh ấy vẫn đến"},
              {"zh": "虽然很累，但是我想继续学习", "vi": "Dù rất mệt nhưng tôi vẫn muốn học tiếp"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "虽然…但是… dùng để?",
          "options": ["Tương phản", "Nguyên nhân", "Giả định"],
          "answer": "Tương phản"
        },
        {
          "type": "fill",
          "question": "虽然生病，___ 还是上班了",
          "answer": "但是",
          "options": ["但是", "所以", "因为", "如果", "已经"]
        },
        {
          "type": "match",
          "pairs": {
            "虽然下雨": "mặc dù mưa",
            "虽然很忙": "mặc dù rất bận",
            "但是没关系": "nhưng không sao",
            "但是我同意": "nhưng tôi đồng ý"
          }
        }
      ]
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Đến cả… cũng… 连…都…",
      "order": 2,
      "content": {
        "introduction":
            "连…都… dùng để nhấn mạnh điều ngoài mong đợi.",
        "outcome": ["Nhấn mạnh mức độ"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "他连名字都忘了", "vi": "Anh ấy quên cả tên"},
              {"zh": "我连饭都没吃", "vi": "Tôi đến cơm cũng chưa ăn"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "连…都… dùng để?",
          "options": ["Nhấn mạnh", "So sánh", "Nguyên nhân"],
          "answer": "Nhấn mạnh"
        },
        {
          "type": "fill",
          "question": "他连手机 ___ 忘了",
          "answer": "都",
          "options": ["都", "也", "还", "就", "才"]
        },
        {
          "type": "match",
          "pairs": {
            "连名字都": "đến cả tên cũng",
            "连时间都": "đến cả thời gian cũng",
            "连一次都没": "đến một lần cũng không",
            "连朋友都不": "đến cả bạn bè cũng không"
          }
        }
      ]
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Càng… càng… 越…越…",
      "order": 3,
      "content": {
        "introduction":
            "越…越… diễn tả sự thay đổi song song.",
        "outcome": ["Diễn tả xu hướng"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "越学越有意思", "vi": "Càng học càng thú vị"},
              {"zh": "天气越冷越想睡觉", "vi": "Càng lạnh càng muốn ngủ"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "越…越… dùng để?",
          "options": ["Xu hướng song song", "Đối lập", "Kết quả"],
          "answer": "Xu hướng song song"
        },
        {
          "type": "fill",
          "question": "越忙 ___ 累",
          "answer": "越",
          "options": ["越", "更", "最", "很", "太"]
        },
        {
          "type": "match",
          "pairs": {
            "越学越难": "càng học càng khó",
            "越想越生气": "càng nghĩ càng tức",
            "越看越喜欢": "càng xem càng thích",
            "越吃越胖": "càng ăn càng mập"
          }
        }
      ]
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Kết quả ngoài dự đoán 结果",
      "order": 4,
      "content": {
        "introduction":
            "结果 dùng để giới thiệu kết quả bất ngờ.",
        "outcome": ["Kể kết quả câu chuyện"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "他努力学习，结果考得很好", "vi": "Anh ấy học chăm, kết quả thi rất tốt"},
              {"zh": "我以为很简单，结果很难", "vi": "Tôi tưởng đơn giản, kết quả lại khó"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "结果 dùng để?",
          "options": ["Nêu kết quả", "So sánh", "Giả định"],
          "answer": "Nêu kết quả"
        },
        {
          "type": "fill",
          "question": "努力了很久，___ 失败了",
          "answer": "结果",
          "options": ["结果", "所以", "因为", "如果", "正在"]
        },
        {
          "type": "match",
          "pairs": {
            "结果成功了": "kết quả là thành công",
            "结果失败了": "kết quả là thất bại",
            "结果迟到了": "kết quả là trễ",
            "结果生病了": "kết quả là bị bệnh"
          }
        }
      ]
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Giả định nhượng bộ 即使…也…",
      "order": 5,
      "content": {
        "introduction":
            "即使…也… dùng khi kết quả không thay đổi dù có điều kiện.",
        "outcome": ["Diễn tả nhượng bộ"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "即使下雨，我也要去", "vi": "Dù mưa tôi cũng sẽ đi"},
              {"zh": "即使很累，也不能放弃", "vi": "Dù rất mệt cũng không bỏ cuộc"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "即使…也… dùng để?",
          "options": ["Nhượng bộ", "So sánh", "Nguyên nhân"],
          "answer": "Nhượng bộ"
        },
        {
          "type": "fill",
          "question": "即使失败，___ 要继续",
          "answer": "也",
          "options": ["也", "就", "才", "还", "都"]
        },
        {
          "type": "match",
          "pairs": {
            "即使下雨": "dù mưa",
            "即使很忙": "dù rất bận",
            "也要坚持": "cũng phải kiên trì",
            "也不放弃": "cũng không bỏ cuộc"
          }
        }
      ]
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Đã… thì… 既然…就…",
      "order": 6,
      "content": {
        "introduction":
            "既然…就… dùng khi điều kiện đã rõ ràng.",
        "outcome": ["Lập luận logic"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "既然来了，就一起吃饭吧", "vi": "Đã đến rồi thì cùng ăn nhé"},
              {"zh": "既然决定了，就不要后悔", "vi": "Đã quyết rồi thì đừng hối hận"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "既然…就… dùng khi?",
          "options": ["Điều kiện đã rõ", "Giả định", "So sánh"],
          "answer": "Điều kiện đã rõ"
        },
        {
          "type": "fill",
          "question": "既然答应了，___ 要做到",
          "answer": "就",
          "options": ["就", "也", "才", "都", "还"]
        },
        {
          "type": "match",
          "pairs": {
            "既然来了": "đã đến rồi",
            "既然知道": "đã biết rồi",
            "就开始吧": "thì bắt đầu đi",
            "就别担心": "thì đừng lo"
          }
        }
      ]
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "Bị động nâng cao với 被",
      "order": 7,
      "content": {
        "introduction":
            "Bị động dùng nhiều trong văn nói và văn viết.",
        "outcome": ["Dùng 被 tự nhiên"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "钱包被人偷走了", "vi": "Ví bị ai đó lấy trộm"},
              {"zh": "计划被取消了", "vi": "Kế hoạch bị hủy"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu nào là bị động?",
          "options": ["计划被取消了", "我取消计划", "计划取消"],
          "answer": "计划被取消了"
        },
        {
          "type": "fill",
          "question": "手机 ___ 偷了",
          "answer": "被",
          "options": ["被", "把", "在", "着", "了"]
        },
        {
          "type": "match",
          "pairs": {
            "被偷走": "bị trộm",
            "被取消": "bị hủy",
            "被批评": "bị phê bình",
            "被表扬": "được khen"
          }
        }
      ]
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Xử lý phức tạp với 把",
      "order": 8,
      "content": {
        "introduction":
            "Câu 把 nâng cao dùng kèm bổ ngữ.",
        "outcome": ["Diễn tả hành động hoàn chỉnh"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我把事情都安排好了", "vi": "Tôi sắp xếp mọi việc xong hết rồi"},
              {"zh": "他把问题解释得很清楚", "vi": "Anh ấy giải thích vấn đề rất rõ"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu 把 nào đúng?",
          "options": [
            "我把事情安排好了",
            "我安排把事情好了",
            "我事情把安排好了"
          ],
          "answer": "我把事情安排好了"
        },
        {
          "type": "fill",
          "question": "把作业 ___ 完",
          "answer": "做",
          "options": ["做", "做了", "做着", "在", "过"]
        },
        {
          "type": "match",
          "pairs": {
            "把事情解决": "giải quyết việc",
            "把门关好": "đóng cửa kỹ",
            "把话说明": "nói rõ lời",
            "把计划完成": "hoàn thành kế hoạch"
          }
        }
      ]
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Đến mức độ… 到…程度",
      "order": 9,
      "content": {
        "introduction":
            "Diễn tả mức độ cao.",
        "outcome": ["Nhấn mạnh mức độ"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "累到说不出话", "vi": "Mệt đến mức không nói được"},
              {"zh": "高兴到睡不着", "vi": "Vui đến mức không ngủ được"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "到… dùng để?",
          "options": ["Mức độ", "Nguyên nhân", "So sánh"],
          "answer": "Mức độ"
        },
        {
          "type": "fill",
          "question": "忙 ___ 没时间吃饭",
          "answer": "到",
          "options": ["到", "得", "了", "着", "过"]
        },
        {
          "type": "match",
          "pairs": {
            "累到不行": "mệt không chịu nổi",
            "高兴到哭": "vui đến khóc",
            "紧张到出汗": "căng thẳng đến toát mồ hôi",
            "难过到流泪": "buồn đến rơi nước mắt"
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
            "Tổng hợp toàn bộ ngữ pháp HSK 4.",
        "outcome": [
          "Chuẩn bị lên HSK 5",
          "Nâng cao đọc – viết"
        ],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"zh": "虽然…但是…", "vi": "mặc dù… nhưng…"},
              {"zh": "连…都…", "vi": "đến cả… cũng…"},
              {"zh": "越…越…", "vi": "càng… càng…"}
            ]
          }
        ]
      },
      "test": [
        {
          "type": "choice",
          "question": "连…都… dùng khi?",
          "options": ["Nhấn mạnh", "So sánh", "Giả định"],
          "answer": "Nhấn mạnh"
        },
        {
          "type": "fill",
          "question": "既然决定了，___ 坚持下去",
          "answer": "就",
          "options": ["就", "也", "才", "都", "还"]
        },
        {
          "type": "match",
          "pairs": {
            "虽然": "mặc dù",
            "即使": "dù cho",
            "既然": "đã",
            "结果": "kết quả"
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

  debugPrint("🔥 DONE: Chinese Level 4 – FULL, MATCH ≥ 4, HSK 4");
}

Future<void> seedChineseLevel3() async {
  final db = FirebaseFirestore.instance;

  final level3Ref = db
      .collection("languages")
      .doc("zh")
      .collection("courses")
      .doc("level_3");

  await level3Ref.set({
    "title": "Lower-Intermediate",
    "subtitle": "Ngữ pháp mở rộng – giao tiếp – HSK 3",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Bổ ngữ kết quả (完 / 好)",
      "order": 1,
      "content": {
        "introduction":
            "Bổ ngữ kết quả dùng để diễn tả hành động đã hoàn thành.",
        "outcome": ["Sử dụng 完 / 好 đúng ngữ cảnh", "Nói hành động hoàn tất"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我吃完饭了", "vi": "Tôi ăn xong rồi"},
              {"zh": "作业做好了", "vi": "Bài tập làm xong rồi"},
              {"zh": "事情办好了", "vi": "Việc đã xử lý xong"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu nào đúng?",
          "options": ["我吃完饭了", "我完吃饭了", "我吃饭完"],
          "answer": "我吃完饭了",
        },
        {
          "type": "fill",
          "question": "作业做 ___ 了",
          "answer": "好",
          "options": ["好", "完", "在", "不", "着"],
        },
        {
          "type": "match",
          "pairs": {
            "吃完": "ăn xong",
            "做好": "làm xong",
            "写完": "viết xong",
            "看完": "xem xong",
          },
        },
      ],
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Câu chữ 把",
      "order": 2,
      "content": {
        "introduction":
            "Câu 把 dùng để nhấn mạnh kết quả của hành động tác động lên tân ngữ.",
        "outcome": ["Sử dụng câu 把"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我把书放在桌子上", "vi": "Tôi đặt sách lên bàn"},
              {"zh": "他把门关上了", "vi": "Anh ấy đóng cửa lại"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu 把 nào đúng?",
          "options": ["我把作业写完了", "我写完把作业了", "我作业把写完了"],
          "answer": "我把作业写完了",
        },
        {
          "type": "fill",
          "question": "我把书 ___ 桌子上",
          "answer": "放在",
          "options": ["放在", "放", "在", "了", "着"],
        },
        {
          "type": "match",
          "pairs": {
            "把门关上": "đóng cửa lại",
            "把书拿走": "mang sách đi",
            "把作业做完": "làm xong bài",
            "把衣服洗干净": "giặt sạch quần áo",
          },
        },
      ],
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Bị động với 被",
      "order": 3,
      "content": {
        "introduction": "Câu 被 dùng để diễn tả hành động bị động.",
        "outcome": ["Hiểu và dùng 被"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "手机被偷了", "vi": "Điện thoại bị trộm mất"},
              {"zh": "作业被老师批评了", "vi": "Bài tập bị thầy phê bình"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "被 dùng để?",
          "options": ["Bị động", "Chủ động", "So sánh"],
          "answer": "Bị động",
        },
        {
          "type": "fill",
          "question": "书 ___ 他拿走了",
          "answer": "被",
          "options": ["被", "把", "在", "着", "了"],
        },
        {
          "type": "match",
          "pairs": {
            "被偷了": "bị trộm",
            "被打破": "bị làm vỡ",
            "被老师表扬": "được thầy khen",
            "被取消": "bị hủy",
          },
        },
      ],
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Đang diễn ra với 正在",
      "order": 4,
      "content": {
        "introduction":
            "正在 nhấn mạnh hành động đang diễn ra tại thời điểm nói.",
        "outcome": ["Diễn tả hiện tại tiếp diễn"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我正在学习中文", "vi": "Tôi đang học tiếng Trung"},
              {"zh": "他们正在开会", "vi": "Họ đang họp"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "正在 dùng để?",
          "options": ["Hành động đang diễn ra", "Quá khứ", "So sánh"],
          "answer": "Hành động đang diễn ra",
        },
        {
          "type": "fill",
          "question": "他正在 ___ 电影",
          "answer": "看",
          "options": ["看", "看了", "看着", "看过", "不看"],
        },
        {
          "type": "match",
          "pairs": {
            "正在学习": "đang học",
            "正在工作": "đang làm việc",
            "正在做饭": "đang nấu ăn",
            "正在开会": "đang họp",
          },
        },
      ],
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Vừa… vừa… 一边…一边…",
      "order": 5,
      "content": {
        "introduction":
            "一边…一边… dùng để diễn tả hai hành động diễn ra đồng thời.",
        "outcome": ["Diễn tả hai hành động cùng lúc"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "他一边吃饭一边看电视", "vi": "Anh ấy vừa ăn vừa xem TV"},
              {"zh": "我一边走一边听音乐", "vi": "Tôi vừa đi vừa nghe nhạc"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "一边…一边… dùng để?",
          "options": ["Hai hành động cùng lúc", "Quá khứ", "So sánh"],
          "answer": "Hai hành động cùng lúc",
        },
        {
          "type": "fill",
          "question": "一边学习 ___ 一边工作",
          "answer": "一边",
          "options": ["一边", "已经", "正在", "但是", "因为"],
        },
        {
          "type": "match",
          "pairs": {
            "一边吃一边看": "vừa ăn vừa xem",
            "一边走一边听": "vừa đi vừa nghe",
            "一边学一边用": "vừa học vừa dùng",
            "一边说一边笑": "vừa nói vừa cười",
          },
        },
      ],
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Càng ngày càng… 越来越",
      "order": 6,
      "content": {
        "introduction": "越来越 diễn tả sự thay đổi tăng dần theo thời gian.",
        "outcome": ["Nói xu hướng thay đổi"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "天气越来越热", "vi": "Thời tiết càng ngày càng nóng"},
              {"zh": "中文越来越难", "vi": "Tiếng Trung ngày càng khó"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "越来越 dùng để?",
          "options": ["Xu hướng tăng", "Quá khứ", "Phủ định"],
          "answer": "Xu hướng tăng",
        },
        {
          "type": "fill",
          "question": "生活 ___ 越来越好",
          "answer": "得",
          "options": ["得", "了", "在", "不", "着"],
        },
        {
          "type": "match",
          "pairs": {
            "越来越好": "ngày càng tốt",
            "越来越贵": "ngày càng đắt",
            "越来越忙": "ngày càng bận",
            "越来越少": "ngày càng ít",
          },
        },
      ],
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "Trải nghiệm với 过",
      "order": 7,
      "content": {
        "introduction": "过 dùng để nói về trải nghiệm trong quá khứ.",
        "outcome": ["Nói đã từng làm gì"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我去过中国", "vi": "Tôi đã từng đi Trung Quốc"},
              {"zh": "我没吃过这个", "vi": "Tôi chưa từng ăn cái này"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "过 dùng để?",
          "options": ["Trải nghiệm", "Hiện tại", "So sánh"],
          "answer": "Trải nghiệm",
        },
        {
          "type": "fill",
          "question": "我去 ___ 北京",
          "answer": "过",
          "options": ["过", "了", "着", "在", "不"],
        },
        {
          "type": "match",
          "pairs": {
            "去过": "đã từng đi",
            "吃过": "đã từng ăn",
            "看过": "đã từng xem",
            "学过": "đã từng học",
          },
        },
      ],
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Vì… nên… 因为…所以…",
      "order": 8,
      "content": {
        "introduction": "Cặp 因为…所以… dùng để nói nguyên nhân – kết quả.",
        "outcome": ["Nêu lý do rõ ràng"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "因为下雨，所以没去", "vi": "Vì mưa nên không đi"},
              {"zh": "因为很忙，所以没时间", "vi": "Vì bận nên không có thời gian"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "因为…所以… dùng để?",
          "options": ["Nguyên nhân – kết quả", "So sánh", "Giả định"],
          "answer": "Nguyên nhân – kết quả",
        },
        {
          "type": "fill",
          "question": "因为生病，___ 没上班",
          "answer": "所以",
          "options": ["所以", "但是", "或者", "正在", "已经"],
        },
        {
          "type": "match",
          "pairs": {
            "因为下雨": "vì mưa",
            "因为太忙": "vì quá bận",
            "所以没去": "nên không đi",
            "所以迟到了": "nên bị trễ",
          },
        },
      ],
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Thời gian kéo dài ～了…了",
      "order": 9,
      "content": {
        "introduction": "…了…了 dùng để diễn tả trạng thái kéo dài.",
        "outcome": ["Nói sự thay đổi trạng thái"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我学了三年中文了", "vi": "Tôi học tiếng Trung 3 năm rồi"},
              {"zh": "他等了一个小时了", "vi": "Anh ấy đợi 1 tiếng rồi"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "…了…了 dùng để?",
          "options": ["Thời gian kéo dài", "Quá khứ ngắn", "So sánh"],
          "answer": "Thời gian kéo dài",
        },
        {
          "type": "fill",
          "question": "我工作了两年 ___",
          "answer": "了",
          "options": ["了", "着", "在", "不", "过"],
        },
        {
          "type": "match",
          "pairs": {
            "学了三年了": "học 3 năm rồi",
            "等了很久了": "đợi lâu rồi",
            "住了五年了": "ở 5 năm rồi",
            "工作了十年了": "làm việc 10 năm rồi",
          },
        },
      ],
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập tổng hợp Level 3",
      "order": 10,
      "content": {
        "introduction": "Ôn tập toàn bộ ngữ pháp HSK 3.",
        "outcome": ["Chuẩn bị lên HSK 4"],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"zh": "把", "vi": "xử lý tân ngữ"},
              {"zh": "被", "vi": "bị động"},
              {"zh": "越来越", "vi": "ngày càng"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu nào đúng?",
          "options": ["我把作业做完了", "我作业把做完了", "我把作业完做了"],
          "answer": "我把作业做完了",
        },
        {
          "type": "fill",
          "question": "我 ___ 去过中国",
          "answer": "已经",
          "options": ["已经", "正在", "不", "被", "把"],
        },
        {
          "type": "match",
          "pairs": {
            "把": "xử lý tân ngữ",
            "被": "bị động",
            "过": "trải nghiệm",
            "完": "hoàn thành",
          },
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

  debugPrint("🔥 DONE: Chinese Level 3 – FULL, MATCH ≥ 4, HSK 3");
}

Future<void> seedChineseLevel2() async {
  final db = FirebaseFirestore.instance;

  final level2Ref = db
      .collection("languages")
      .doc("zh")
      .collection("courses")
      .doc("level_2");

  await level2Ref.set({
    "title": "Elementary",
    "subtitle": "Ngữ pháp cơ bản – giao tiếp – HSK 2",
  }, SetOptions(merge: true));

  final lessons = {
    // ====================== LESSON 1 ======================
    "lesson_1": {
      "title": "Câu khẳng định đơn giản",
      "order": 1,
      "content": {
        "introduction": "Ôn tập và mở rộng câu khẳng định trong tiếng Trung.",
        "outcome": ["Tạo câu khẳng định", "Sử dụng đúng trật tự câu"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "zh": "我是学生",
                "pinyin": "wǒ shì xuéshēng",
                "vi": "Tôi là học sinh",
              },
              {"zh": "他很高", "pinyin": "tā hěn gāo", "vi": "Anh ấy cao"},
              {
                "zh": "我喜欢中文",
                "pinyin": "wǒ xǐhuān zhōngwén",
                "vi": "Tôi thích tiếng Trung",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu nào đúng?",
          "options": ["我是学生", "我学生是", "学生我是"],
          "answer": "我是学生",
        },
        {
          "type": "fill",
          "question": "我 ___ 老师",
          "answer": "是",
          "options": ["是", "有", "在", "不", "很"],
        },
        {
          "type": "match",
          "pairs": {
            "我是学生": "Tôi là học sinh",
            "他是老师": "Anh ấy là giáo viên",
            "我很忙": "Tôi rất bận",
            "她很漂亮": "Cô ấy xinh đẹp",
          },
        },
      ],
    },

    // ====================== LESSON 2 ======================
    "lesson_2": {
      "title": "Phủ định với 不",
      "order": 2,
      "content": {
        "introduction": "Cách phủ định hành động ở hiện tại và tương lai.",
        "outcome": ["Sử dụng 不 đúng ngữ cảnh"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我不去", "pinyin": "wǒ bù qù", "vi": "Tôi không đi"},
              {
                "zh": "他不喜欢咖啡",
                "pinyin": "tā bù xǐhuān kāfēi",
                "vi": "Anh ấy không thích cà phê",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Phủ định của 喜欢?",
          "options": ["不喜欢", "没喜欢", "不是喜欢"],
          "answer": "不喜欢",
        },
        {
          "type": "fill",
          "question": "我 ___ 喝酒",
          "answer": "不",
          "options": ["不", "没", "在", "是", "有"],
        },
        {
          "type": "match",
          "pairs": {
            "不去": "không đi",
            "不吃": "không ăn",
            "不喜欢": "không thích",
            "不看": "không xem",
          },
        },
      ],
    },

    // ====================== LESSON 3 ======================
    "lesson_3": {
      "title": "Quá khứ với 了",
      "order": 3,
      "content": {
        "introduction": "Diễn tả hành động đã hoàn thành.",
        "outcome": ["Nói hành động trong quá khứ"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我吃了饭", "pinyin": "wǒ chī le fàn", "vi": "Tôi đã ăn cơm"},
              {
                "zh": "他去了学校",
                "pinyin": "tā qù le xuéxiào",
                "vi": "Anh ấy đã đi học",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Câu nào diễn tả quá khứ?",
          "options": ["我吃了饭", "我吃饭", "我不吃饭"],
          "answer": "我吃了饭",
        },
        {
          "type": "fill",
          "question": "他去了 ___",
          "answer": "学校",
          "options": ["学校", "学生", "学习", "老师", "汉语"],
        },
        {
          "type": "match",
          "pairs": {
            "吃了": "đã ăn",
            "去了": "đã đi",
            "看了": "đã xem",
            "买了": "đã mua",
          },
        },
      ],
    },

    // ====================== LESSON 4 ======================
    "lesson_4": {
      "title": "Đang làm gì với 在",
      "order": 4,
      "content": {
        "introduction": "Diễn tả hành động đang diễn ra.",
        "outcome": ["Nói hành động hiện tại tiếp diễn"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我在学习", "pinyin": "wǒ zài xuéxí", "vi": "Tôi đang học"},
              {
                "zh": "他在工作",
                "pinyin": "tā zài gōngzuò",
                "vi": "Anh ấy đang làm việc",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Từ chỉ hành động đang diễn ra?",
          "options": ["在", "了", "不"],
          "answer": "在",
        },
        {
          "type": "fill",
          "question": "我在 ___ 中文",
          "answer": "学习",
          "options": ["学习", "学生", "学校", "喜欢", "老师"],
        },
        {
          "type": "match",
          "pairs": {
            "在学习": "đang học",
            "在工作": "đang làm việc",
            "在看书": "đang đọc sách",
            "在吃饭": "đang ăn cơm",
          },
        },
      ],
    },

    // ====================== LESSON 5 ======================
    "lesson_5": {
      "title": "Số lượng với 有",
      "order": 5,
      "content": {
        "introduction": "Diễn tả sự sở hữu.",
        "outcome": ["Nói có hay không có"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "zh": "我有一个朋友",
                "pinyin": "wǒ yǒu yí gè péngyou",
                "vi": "Tôi có một người bạn",
              },
              {
                "zh": "他没有钱",
                "pinyin": "tā méi yǒu qián",
                "vi": "Anh ấy không có tiền",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Phủ định của 有?",
          "options": ["没有", "不有", "不是"],
          "answer": "没有",
        },
        {
          "type": "fill",
          "question": "我 ___ 时间",
          "answer": "有",
          "options": ["有", "在", "是", "了", "不"],
        },
        {
          "type": "match",
          "pairs": {
            "有钱": "có tiền",
            "有时间": "có thời gian",
            "有朋友": "có bạn",
            "没有问题": "không có vấn đề",
          },
        },
      ],
    },

    // ====================== LESSON 6 ======================
    "lesson_6": {
      "title": "Hỏi với 吗",
      "order": 6,
      "content": {
        "introduction": "Tạo câu hỏi Yes/No.",
        "outcome": ["Hỏi và trả lời đơn giản"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "zh": "你是学生吗？",
                "pinyin": "nǐ shì xuéshēng ma",
                "vi": "Bạn là học sinh không?",
              },
              {
                "zh": "他去学校吗？",
                "pinyin": "tā qù xuéxiào ma",
                "vi": "Anh ấy đi học không?",
              },
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "Từ nào dùng để tạo câu hỏi?",
          "options": ["吗", "了", "不"],
          "answer": "吗",
        },
        {
          "type": "fill",
          "question": "你喜欢中文 ___？",
          "answer": "吗",
          "options": ["吗", "呢", "吧", "了", "在"],
        },
        {
          "type": "match",
          "pairs": {
            "是吗": "có phải không",
            "去吗": "đi không",
            "好吗": "được không",
            "对吗": "đúng không",
          },
        },
      ],
    },

    // ====================== LESSON 7 ======================
    "lesson_7": {
      "title": "So sánh với 比",
      "order": 7,
      "content": {
        "introduction": "So sánh hai đối tượng.",
        "outcome": ["So sánh hơn"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {
                "zh": "我比他高",
                "pinyin": "wǒ bǐ tā gāo",
                "vi": "Tôi cao hơn anh ấy",
              },
              {"zh": "今天比昨天冷", "pinyin": "", "vi": "Hôm nay lạnh hơn hôm qua"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "比 dùng để?",
          "options": ["So sánh", "Phủ định", "Quá khứ"],
          "answer": "So sánh",
        },
        {
          "type": "fill",
          "question": "我比你 ___",
          "answer": "高",
          "options": ["高", "了", "在", "不", "有"],
        },
        {
          "type": "match",
          "pairs": {
            "比他高": "cao hơn anh ấy",
            "比我大": "lớn hơn tôi",
            "比昨天冷": "lạnh hơn hôm qua",
            "比以前好": "tốt hơn trước",
          },
        },
      ],
    },

    // ====================== LESSON 8 ======================
    "lesson_8": {
      "title": "Thời gian với 前 / 后",
      "order": 8,
      "content": {
        "introduction": "Diễn tả thời gian trước và sau.",
        "outcome": ["Nói mốc thời gian"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "三天前", "pinyin": "sān tiān qián", "vi": "ba ngày trước"},
              {"zh": "下课后", "pinyin": "xià kè hòu", "vi": "sau khi tan học"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "前 nghĩa là?",
          "options": ["Trước", "Sau", "Trong"],
          "answer": "Trước",
        },
        {
          "type": "fill",
          "question": "吃饭 ___ 我去工作",
          "answer": "后",
          "options": ["后", "前", "了", "在", "比"],
        },
        {
          "type": "match",
          "pairs": {
            "上课前": "trước giờ học",
            "下班后": "sau khi tan làm",
            "三年前": "ba năm trước",
            "吃饭后": "sau khi ăn",
          },
        },
      ],
    },

    // ====================== LESSON 9 ======================
    "lesson_9": {
      "title": "Mong muốn với 想",
      "order": 9,
      "content": {
        "introduction": "Diễn tả mong muốn và dự định.",
        "outcome": ["Nói muốn làm gì"],
        "sections": [
          {
            "type": "grammar",
            "title": "Ví dụ",
            "items": [
              {"zh": "我想学习中文", "pinyin": "", "vi": "Tôi muốn học tiếng Trung"},
              {"zh": "他想去中国", "pinyin": "", "vi": "Anh ấy muốn đi Trung Quốc"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "想 dùng để?",
          "options": ["Mong muốn", "Quá khứ", "Phủ định"],
          "answer": "Mong muốn",
        },
        {
          "type": "fill",
          "question": "我想 ___ 饭",
          "answer": "吃",
          "options": ["吃", "吃了", "吃着", "不", "在"],
        },
        {
          "type": "match",
          "pairs": {
            "想学习": "muốn học",
            "想工作": "muốn làm việc",
            "想休息": "muốn nghỉ ngơi",
            "想旅行": "muốn du lịch",
          },
        },
      ],
    },

    // ====================== LESSON 10 ======================
    "lesson_10": {
      "title": "Ôn tập Level 2",
      "order": 10,
      "content": {
        "introduction": "Ôn tập toàn bộ ngữ pháp HSK 2.",
        "outcome": ["Củng cố giao tiếp cơ bản"],
        "sections": [
          {
            "type": "review",
            "title": "Tổng hợp",
            "items": [
              {"zh": "不去", "vi": "không đi"},
              {"zh": "吃了", "vi": "đã ăn"},
              {"zh": "在学习", "vi": "đang học"},
            ],
          },
        ],
      },
      "test": [
        {
          "type": "choice",
          "question": "我在学习 nghĩa là?",
          "options": ["Tôi đang học", "Tôi đã học", "Tôi không học"],
          "answer": "Tôi đang học",
        },
        {
          "type": "fill",
          "question": "我 ___ 学习中文",
          "answer": "想",
          "options": ["想", "了", "在", "不", "比"],
        },
        {
          "type": "match",
          "pairs": {"不": "không", "了": "đã", "在": "đang", "想": "muốn"},
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

  debugPrint("🔥 DONE: Chinese Level 2 – 10 lessons, MATCH ≥ 4, FULL");
}

Future<void> migrateFillQuestionsToChoiceZh() async {
  final db = FirebaseFirestore.instance;

  final lessonsRef = db
      .collection("languages")
      .doc("zh")
      .collection("courses")
      .doc("level_1")
      .collection("lessons");

  final snapshot = await lessonsRef.get();

  // 🔹 Từ nhiễu dùng chung cho beginner tiếng Trung
  final distractors = ["我", "你", "他", "她", "他们", "这", "那", "这里", "那里", "现在"];

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

        return {...q, "options": options.toList()..shuffle()};
      }

      return q;
    }).toList();

    if (updated) {
      await lesson.reference.update({"test": newTests});
      debugPrint("✅ Migrated fill → choice (Chinese) in ${lesson.id}");
    }
  }

  debugPrint("🔥 DONE: All Chinese fill questions converted");
}

Future<void> updateLesson2To10ContentZh() async {
  final db = FirebaseFirestore.instance;

  final lessons = {
    "lesson_2": {
      "introduction": "Học các câu chào hỏi cơ bản trong giao tiếp hằng ngày.",
      "outcome": [
        "Biết cách chào hỏi theo ngữ cảnh",
        "Phản xạ giao tiếp tự nhiên",
      ],
      "sections": [
        {
          "type": "sentence",
          "title": "Câu chào hỏi",
          "items": [
            {"zh": "早上好", "pinyin": "zǎo shàng hǎo", "vi": "Chào buổi sáng"},
            {"zh": "你好", "pinyin": "nǐ hǎo", "vi": "Xin chào"},
            {"zh": "晚上好", "pinyin": "wǎn shàng hǎo", "vi": "Chào buổi tối"},
          ],
        },
      ],
    },

    "lesson_3": {
      "introduction": "Học cách giới thiệu bản thân bằng tiếng Trung.",
      "outcome": ["Biết giới thiệu tên", "Làm quen cấu trúc câu 我叫～"],
      "sections": [
        {
          "type": "sentence",
          "title": "Giới thiệu bản thân",
          "items": [
            {"zh": "我叫安。", "pinyin": "wǒ jiào Ān", "vi": "Tôi là An"},
            {
              "zh": "很高兴认识你。",
              "pinyin": "hěn gāo xìng rèn shí nǐ",
              "vi": "Rất vui được gặp bạn",
            },
          ],
        },
      ],
    },

    "lesson_4": {
      "introduction": "Làm quen với số đếm từ 1 đến 5.",
      "outcome": ["Nhớ số cơ bản", "Ứng dụng trong giao tiếp"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Số đếm",
          "items": [
            {"zh": "一", "pinyin": "yī", "vi": "1"},
            {"zh": "二", "pinyin": "èr", "vi": "2"},
            {"zh": "三", "pinyin": "sān", "vi": "3"},
            {"zh": "四", "pinyin": "sì", "vi": "4"},
            {"zh": "五", "pinyin": "wǔ", "vi": "5"},
          ],
        },
      ],
    },

    "lesson_5": {
      "introduction": "Từ vựng các đồ vật quen thuộc.",
      "outcome": ["Gọi tên đồ vật xung quanh", "Mở rộng vốn từ"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Đồ vật",
          "items": [
            {"zh": "书", "pinyin": "shū", "vi": "Sách"},
            {"zh": "笔", "pinyin": "bǐ", "vi": "Bút"},
            {"zh": "包", "pinyin": "bāo", "vi": "Cặp"},
          ],
        },
      ],
    },

    "lesson_6": {
      "introduction": "Học cách nói câu khẳng định và phủ định.",
      "outcome": ["Nói câu khẳng định", "Nói câu phủ định"],
      "sections": [
        {
          "type": "grammar",
          "title": "Cấu trúc câu",
          "items": [
            {"zh": "是", "pinyin": "shì", "vi": "là"},
            {"zh": "不是", "pinyin": "bú shì", "vi": "không phải"},
          ],
        },
      ],
    },

    "lesson_7": {
      "introduction": "Học từ vựng về gia đình.",
      "outcome": ["Giới thiệu gia đình", "Nhận biết từ xưng hô"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Gia đình",
          "items": [
            {"zh": "爸爸", "pinyin": "bà ba", "vi": "Bố"},
            {"zh": "妈妈", "pinyin": "mā ma", "vi": "Mẹ"},
            {"zh": "哥哥", "pinyin": "gē ge", "vi": "Anh trai"},
          ],
        },
      ],
    },

    "lesson_8": {
      "introduction": "Các từ chỉ thời gian thường dùng.",
      "outcome": ["Nói về thời gian", "Hiểu ngữ cảnh câu"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Thời gian",
          "items": [
            {"zh": "今天", "pinyin": "jīn tiān", "vi": "Hôm nay"},
            {"zh": "明天", "pinyin": "míng tiān", "vi": "Ngày mai"},
            {"zh": "现在", "pinyin": "xiàn zài", "vi": "Bây giờ"},
          ],
        },
      ],
    },

    "lesson_9": {
      "introduction": "Các động từ cơ bản trong sinh hoạt.",
      "outcome": ["Nhận biết động từ", "Sử dụng trong câu đơn"],
      "sections": [
        {
          "type": "vocabulary",
          "title": "Động từ",
          "items": [
            {"zh": "吃", "pinyin": "chī", "vi": "Ăn"},
            {"zh": "喝", "pinyin": "hē", "vi": "Uống"},
            {"zh": "去", "pinyin": "qù", "vi": "Đi"},
          ],
        },
      ],
    },

    "lesson_10": {
      "introduction": "Hội thoại chào hỏi và hỏi tên.",
      "outcome": ["Thực hành hội thoại", "Phản xạ giao tiếp"],
      "sections": [
        {
          "type": "sentence",
          "title": "Hội thoại",
          "items": [
            {"zh": "你好", "pinyin": "nǐ hǎo", "vi": "Xin chào"},
            {
              "zh": "你叫什么名字？",
              "pinyin": "nǐ jiào shén me míng zì",
              "vi": "Tên bạn là gì?",
            },
            {"zh": "我叫安。", "pinyin": "wǒ jiào Ān", "vi": "Tôi là An"},
          ],
        },
      ],
    },
  };

  for (final entry in lessons.entries) {
    await db
        .collection("languages")
        .doc("zh")
        .collection("courses")
        .doc("level_1")
        .collection("lessons")
        .doc(entry.key)
        .update({"content": entry.value});

    debugPrint("✅ Updated ${entry.key} (Chinese)");
  }

  debugPrint("🔥 ALL Chinese lesson 2 → 10 UPDATED");
}

Future<void> updateLesson1ContentZh() async {
  final db = FirebaseFirestore.instance;

  final lessonRef = db
      .collection("languages")
      .doc("zh")
      .collection("courses")
      .doc("level_1")
      .collection("lessons")
      .doc("lesson_1");

  final newContent = {
    "introduction":
        "Trong bài học này, bạn sẽ làm quen với các nguyên âm cơ bản trong tiếng Trung (Pinyin).",
    "outcome": [
      "Nhận biết và đọc đúng a – o – e – i – u",
      "Phát âm chuẩn các nguyên âm Pinyin",
      "Làm quen với thanh điệu tiếng Trung",
    ],
    "sections": [
      {
        "type": "phonetic",
        "title": "Ngữ âm Pinyin",
        "items": [
          {
            "zh": "a",
            "pinyin": "a",
            "vi": "a",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Pinyin_chart.svg/1280px-Pinyin_chart.svg.png",
          },
          {
            "zh": "o",
            "pinyin": "o",
            "vi": "o",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Pinyin_chart.svg/1280px-Pinyin_chart.svg.png",
          },
          {
            "zh": "e",
            "pinyin": "e",
            "vi": "e",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Pinyin_chart.svg/1280px-Pinyin_chart.svg.png",
          },
          {
            "zh": "i",
            "pinyin": "i",
            "vi": "i",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Pinyin_chart.svg/1280px-Pinyin_chart.svg.png",
          },
          {
            "zh": "u",
            "pinyin": "u",
            "vi": "u",
            "image":
                "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Pinyin_chart.svg/1280px-Pinyin_chart.svg.png",
          },
        ],
      },
      {
        "type": "example",
        "title": "Ví dụ đơn giản",
        "items": [
          {"zh": "妈妈", "pinyin": "mā ma", "vi": "mẹ"},
          {"zh": "爸爸", "pinyin": "bà ba", "vi": "bố"},
        ],
      },
    ],
  };

  await lessonRef.update({"content": newContent});

  debugPrint("🔥 Chinese lesson_1 content UPDATED");
}

Future<void> updateLessonOrderLevel1Zh() async {
  final db = FirebaseFirestore.instance;

  final lessonsRef = db
      .collection("languages")
      .doc("zh")
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

  debugPrint("🔥 DONE: order field added to all Chinese level_1 lessons");
}

Future<void> addMoreLessonsLevel1Zh() async {
  final db = FirebaseFirestore.instance;

  final level1Lessons = db
      .collection("languages")
      .doc("zh")
      .collection("courses")
      .doc("level_1")
      .collection("lessons");

  final newLessons = [
    {
      "id": "lesson_3",
      "title": "Giới thiệu bản thân",
      "content": """
## Giới thiệu bản thân

- 我 : Tôi
- 名字 : Tên

Mẫu câu:
- 我叫安。
""",
      "test": [
        {
          "type": "choice",
          "question": "Câu nào dùng để giới thiệu bản thân?",
          "options": ["谢谢", "我叫安", "再见"],
          "answer": "我叫安",
        },
        {"type": "fill", "question": "___ 叫 安。", "answer": "我"},
        {
          "type": "match",
          "pairs": {"我": "Tôi", "名字": "Tên"},
        },
      ],
    },

    {
      "id": "lesson_4",
      "title": "Số đếm & tuổi",
      "content": """
## Số đếm

- 一 : 1
- 二 : 2
- 三 : 3
- 四 : 4
- 五 : 5
""",
      "test": [
        {
          "type": "choice",
          "question": "Số 4 viết là?",
          "options": ["三", "四", "五"],
          "answer": "四",
        },
        {"type": "fill", "question": "三 = ___", "answer": "3"},
        {
          "type": "match",
          "pairs": {"一": "1", "二": "2", "三": "3"},
        },
      ],
    },

    {
      "id": "lesson_5",
      "title": "Đồ vật quen thuộc",
      "content": """
## Đồ vật

- 书 : Sách
- 笔 : Bút
- 包 : Cặp
""",
      "test": [
        {
          "type": "choice",
          "question": "书 là gì?",
          "options": ["Bút", "Sách", "Cặp"],
          "answer": "Sách",
        },
        {"type": "fill", "question": "笔 = ___", "answer": "Bút"},
        {
          "type": "match",
          "pairs": {"书": "Sách", "笔": "Bút", "包": "Cặp"},
        },
      ],
    },

    {
      "id": "lesson_6",
      "title": "Câu khẳng định – phủ định",
      "content": """
## Khẳng định & phủ định

- 是 : là
- 不是 : không phải
""",
      "test": [
        {
          "type": "choice",
          "question": "Câu phủ định là?",
          "options": ["是", "不是", "有"],
          "answer": "不是",
        },
        {"type": "fill", "question": "这是书 ___。", "answer": "不是"},
        {
          "type": "match",
          "pairs": {"是": "là", "不是": "không phải"},
        },
      ],
    },

    {
      "id": "lesson_7",
      "title": "Gia đình",
      "content": """
## Gia đình

- 爸爸 : Bố
- 妈妈 : Mẹ
- 哥哥 : Anh trai
""",
      "test": [
        {
          "type": "choice",
          "question": "妈妈 là ai?",
          "options": ["Bố", "Mẹ", "Anh"],
          "answer": "Mẹ",
        },
        {"type": "fill", "question": "这是 ___。", "answer": "爸爸"},
        {
          "type": "match",
          "pairs": {"爸爸": "Bố", "妈妈": "Mẹ", "哥哥": "Anh trai"},
        },
      ],
    },

    {
      "id": "lesson_8",
      "title": "Thời gian – ngày tháng",
      "content": """
## Thời gian

- 今天 : Hôm nay
- 明天 : Ngày mai
- 现在 : Bây giờ
""",
      "test": [
        {
          "type": "choice",
          "question": "今天 nghĩa là?",
          "options": ["Hôm nay", "Ngày mai", "Hôm qua"],
          "answer": "Hôm nay",
        },
        {"type": "fill", "question": "现在 = ___", "answer": "Bây giờ"},
        {
          "type": "match",
          "pairs": {"今天": "Hôm nay", "明天": "Ngày mai", "现在": "Bây giờ"},
        },
      ],
    },

    {
      "id": "lesson_9",
      "title": "Động từ cơ bản",
      "content": """
## Động từ

- 吃 : Ăn
- 喝 : Uống
- 去 : Đi
""",
      "test": [
        {
          "type": "choice",
          "question": "吃 nghĩa là?",
          "options": ["Uống", "Ăn", "Đi"],
          "answer": "Ăn",
        },
        {"type": "fill", "question": "喝 = ___", "answer": "Uống"},
        {
          "type": "match",
          "pairs": {"吃": "Ăn", "喝": "Uống", "去": "Đi"},
        },
      ],
    },

    {
      "id": "lesson_10",
      "title": "Hội thoại đơn giản",
      "content": """
## Hội thoại

- A: 你好
- B: 你好
- A: 你叫什么名字？
- B: 我叫安。
""",
      "test": [
        {
          "type": "choice",
          "question": "你叫什么名字？ nghĩa là?",
          "options": ["Xin chào", "Tên bạn là gì?", "Bạn khỏe không?"],
          "answer": "Tên bạn là gì?",
        },
        {"type": "fill", "question": "我叫 ___。", "answer": "安"},
        {
          "type": "match",
          "pairs": {"你好": "Xin chào", "名字": "Tên", "叫": "gọi là"},
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

  debugPrint("✅ Added lesson_3 → lesson_10 to level_1 (Chinese)");
}

Future<void> seedChineseData() async {
  final db = FirebaseFirestore.instance;

  final zh = db.collection("languages").doc("zh");

  await zh.set({"name": "Chinese"});

  final levels = [
    {
      "id": "level_1",
      "title": "Beginner",
      "subtitle": "Pinyin & chào hỏi cơ bản",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Pinyin a–o",
          "content": """
## Pinyin a–o

### Nguyên âm
- a
- o
- e
- i
- u

### Ví dụ
- mā (妈 – mẹ)
- bā (八 – số 8)
""",
          "test": [
            {
              "type": "choice",
              "question": "Âm nào đọc là **a**?",
              "options": ["o", "a", "e"],
              "answer": "a",
            },
            {"type": "fill", "question": "Điền âm đúng: ___ mā", "answer": "a"},
            {
              "type": "match",
              "pairs": {"a": "a", "o": "o", "e": "e"},
            },
          ],
        },
        {
          "id": "lesson_2",
          "title": "Chào hỏi cơ bản",
          "content": """
## Chào hỏi cơ bản

- 你好 : Xin chào
- 早上好 : Chào buổi sáng
- 晚上好 : Chào buổi tối
""",
          "test": [
            {
              "type": "choice",
              "question": "Câu nào dùng để chào chung?",
              "options": ["早上好", "你好", "晚上好"],
              "answer": "你好",
            },
            {"type": "fill", "question": "Điền chữ đúng: ___ 好", "answer": "你"},
            {
              "type": "match",
              "pairs": {
                "你好": "Xin chào",
                "早上好": "Chào sáng",
                "晚上好": "Chào tối",
              },
            },
          ],
        },
      ],
    },
    {
      "id": "level_2",
      "title": "Elementary",
      "subtitle": "Từ vựng & ngữ pháp HSK 1",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Giới thiệu bản thân",
          "content": """
## Giới thiệu bản thân

Mẫu câu:
- 我叫南。
- 很高兴认识你。
""",
          "test": [
            {
              "type": "choice",
              "question": "Câu nào dùng để tự giới thiệu?",
              "options": ["谢谢", "我叫南", "再见"],
              "answer": "我叫南",
            },
            {"type": "fill", "question": "___ 叫 南。", "answer": "我"},
            {
              "type": "match",
              "pairs": {
                "谢谢": "Cảm ơn",
                "再见": "Tạm biệt",
                "很高兴认识你": "Rất vui được gặp",
              },
            },
          ],
        },
        {
          "id": "lesson_2",
          "title": "Số đếm 1–10",
          "content": """
## Số đếm

1 一  
2 二  
3 三  
4 四  
5 五  
""",
          "test": [
            {
              "type": "choice",
              "question": "Số 3 viết thế nào?",
              "options": ["二", "三", "四"],
              "answer": "三",
            },
            {"type": "fill", "question": "四 = ___", "answer": "4"},
            {
              "type": "match",
              "pairs": {"一": "1", "二": "2", "三": "3"},
            },
          ],
        },
      ],
    },
    {
      "id": "level_3",
      "title": "Pre-Intermediate",
      "subtitle": "Ngữ pháp HSK 2",
      "lessons": [
        {
          "id": "lesson_1",
          "title": "Cấu trúc 正在",
          "content": """
## 正在

Dùng để diễn tả hành động đang xảy ra.

Ví dụ:
- 我正在学习。
""",
          "test": [
            {
              "type": "choice",
              "question": "正在 dùng để diễn tả?",
              "options": ["quá khứ", "đang diễn ra", "tương lai"],
              "answer": "đang diễn ra",
            },
            {"type": "fill", "question": "我 ___ 学习。", "answer": "正在"},
            {
              "type": "match",
              "pairs": {"学习": "học", "工作": "làm việc"},
            },
          ],
        },
        {
          "id": "lesson_2",
          "title": "Mẫu câu ～了",
          "content": """
## ～了

Diễn tả hành động đã hoàn thành.
""",
          "test": [
            {
              "type": "choice",
              "question": "～了 dùng để diễn tả?",
              "options": ["đã xong", "đang làm", "chưa làm"],
              "answer": "đã xong",
            },
            {"type": "fill", "question": "我吃 ___。", "answer": "了"},
            {
              "type": "match",
              "pairs": {"吃了": "đã ăn", "走了": "đã đi"},
            },
          ],
        },
      ],
    },
    {
      "id": "level_4",
      "title": "Intermediate",
      "subtitle": "Đọc hiểu & nghe HSK 3",
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
              "answer": "Công việc",
            },
            {"type": "fill", "question": "他是 ___。", "answer": "老师"},
            {
              "type": "match",
              "pairs": {"老师": "giáo viên", "公司": "công ty"},
            },
          ],
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
              "question": "Hai người đang ở đâu?",
              "options": ["学校", "火车站", "商店"],
              "answer": "火车站",
            },
            {"type": "fill", "question": "目的地是 ___。", "answer": "北京"},
            {
              "type": "match",
              "pairs": {"火车站": "nhà ga", "票": "vé"},
            },
          ],
        },
      ],
    },
  ];

  for (final level in levels) {
    final levelRef = zh.collection("courses").doc(level["id"] as String);

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

  debugPrint("🔥 FULL CHINESE DATA SEEDED");
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await seedReadingTests();
  runApp(const SeedApp());
}

class SeedApp extends StatelessWidget {
  const SeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "✅ 3 IELTS Reading Tests seeded successfully (FULL CONTENT)",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/* ============================================================
   SEED
============================================================ */

Future<void> seedReadingTests() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  final tests = [
  _attachExplainAndEvidence(_testUrbanTransport()),
  _attachExplainAndEvidence(_testWildlifeConservation()),
  _attachExplainAndEvidence(_testHumanMemory()),
];


  for (var test in tests) {
    final ref =
        firestore.collection("reading_tests").doc("test_${test['id']}");
    batch.set(ref, test);
  }

  await batch.commit();
}

/* ============================================================
   TEST 1 – URBAN TRANSPORT (20 QUESTIONS)
============================================================ */

Map<String, dynamic> _testUrbanTransport() {
  return {
    "id": 1,
    "title": "IELTS Academic Reading Test 1",
    "duration": 60,
    "totalQuestions": 20,
    "createdAt": FieldValue.serverTimestamp(),
    "passages": [
      {
        "id": 1,
        "title": "The Development of Urban Transport Systems",
        "content":
            "Cities have always depended on transportation systems to function effectively. "
            "In early urban environments, most people travelled on foot or relied on animal-powered "
            "vehicles such as carts and carriages. These methods were sufficient for small populations "
            "but became increasingly inefficient as cities expanded.\n\n"
            "During the nineteenth century, technological innovation transformed urban mobility. "
            "Steam-powered trams and railways allowed people to travel longer distances in shorter "
            "periods of time. This change enabled workers to live further from their workplaces, "
            "leading to the growth of suburban areas.\n\n"
            "In the modern era, cities face serious challenges including congestion, pollution, "
            "and climate change. As a result, governments are investing in sustainable transport "
            "solutions such as electric buses, underground rail systems, and cycling infrastructure.",
        "questions": [
          _mcq(1, "What is the main focus of the passage?",
              ["Rural travel", "Urban transport evolution", "Tourism", "City law"], "Urban transport evolution"),
          _tfng(2, "Early transport systems were suitable for large cities.", "FALSE"),
          _tfng(3, "Steam-powered transport enabled suburban growth.", "TRUE"),
          _tfng(4, "Modern cities face environmental transport challenges.", "TRUE"),
          _sentence(5, "Urban expansion led to the growth of ________ areas.", "suburban"),
          _mcq(6, "Which transport was common in early cities?",
              ["Cars", "Buses", "Animal-powered vehicles", "Subways"], "Animal-powered vehicles"),
          _tfng(7, "Cycling infrastructure is mentioned as a solution.", "TRUE")
        ]
      },
      {
        "id": 2,
        "title": "Private Cars and Urban Challenges",
        "content":
            "The widespread adoption of private cars in the twentieth century dramatically "
            "changed urban life. Cars provided individuals with flexibility and convenience, "
            "but their rapid growth also created significant problems.\n\n"
            "Road congestion became common in large cities, while air pollution increased "
            "due to vehicle emissions. Public spaces were often reduced to make room for "
            "roads and parking facilities.\n\n"
            "Today, many cities are attempting to reduce their dependence on private cars "
            "by promoting public transport, cycling, and walking.",
        "questions": [
          _mcq(8, "What problem is associated with private cars?",
              ["Lower costs", "Air pollution", "Better health", "Faster travel"], "Air pollution"),
          _tfng(9, "Private cars reduced the need for roads.", "FALSE"),
          _tfng(10, "Cities are encouraging alternatives to car use.", "TRUE"),
          _sentence(11, "Vehicle emissions contribute to air ________.", "pollution"),
          _mcq(12, "What advantage do cars offer individuals?",
              ["Flexibility", "Lower pollution", "Free parking", "Safety"], "Flexibility"),
          _tfng(13, "Public transport is being promoted.", "TRUE")
        ]
      },
      {
        "id": 3,
        "title": "The Future of City Mobility",
        "content":
            "Technological innovation continues to shape the future of urban mobility. "
            "Electric vehicles and intelligent traffic systems aim to reduce emissions "
            "and improve efficiency.\n\n"
            "However, experts argue that technology alone cannot solve urban transport problems. "
            "City planners increasingly emphasise designing cities that prioritise people "
            "rather than vehicles.\n\n"
            "Walkable neighbourhoods and integrated transport networks are now seen as "
            "essential features of sustainable urban development.",
        "questions": [
          _sentence(14, "Cities should prioritise ________ over vehicles.", "people"),
          _tfng(15, "Technology alone can solve transport problems.", "FALSE"),
          _mcq(16, "What do planners emphasise?",
              ["More roads", "Human-focused design", "Higher taxes", "Private cars"], "Human-focused design"),
          _tfng(17, "Walkable areas are important for sustainability.", "TRUE"),
          _sentence(18, "Smart systems aim to improve transport ________.", "efficiency"),
          _mcq(19, "Which is NOT mentioned?",
              ["Electric vehicles", "Smart traffic", "Flying cars", "Urban planning"], "Flying cars"),
          _tfng(20, "Future mobility considers environmental impact.", "TRUE")
        ]
      }
    ]
  };
}

/* ============================================================
   TEST 2 – WILDLIFE CONSERVATION (20 QUESTIONS)
============================================================ */

Map<String, dynamic> _testWildlifeConservation() {
  return {
    "id": 2,
    "title": "IELTS Academic Reading Test 2",
    "duration": 60,
    "totalQuestions": 20,
    "createdAt": FieldValue.serverTimestamp(),
    "passages": [
      {
        "id": 1,
        "title": "Protecting Endangered Species",
        "content":
            "Wildlife conservation has become a global concern as human activities "
            "continue to damage natural ecosystems. Habitat destruction, pollution, "
            "and climate change have caused rapid declines in many animal populations.\n\n"
            "Conservation efforts often focus on protecting natural habitats and enforcing "
            "laws against illegal hunting and trade. In some cases, captive breeding "
            "programmes are used to restore endangered species.\n\n"
            "Despite these efforts, conservation remains challenging due to limited "
            "funding and conflicting economic interests.",
        "questions": [
          _mcq(1, "What threatens wildlife populations?",
              ["Education", "Habitat destruction", "Migration", "Tourism"], "Habitat destruction"),
          _tfng(2, "Climate change affects wildlife.", "TRUE"),
          _sentence(3, "Many species face ________ due to human activity.", "extinction"),
          _tfng(4, "Illegal hunting is addressed by conservation laws.", "TRUE"),
          _mcq(5, "What method helps restore species?",
              ["Deforestation", "Captive breeding", "Urbanisation", "Pollution"], "Captive breeding"),
          _tfng(6, "Conservation is easy to implement.", "FALSE"),
          _sentence(7, "Protecting natural ________ is a key strategy.", "habitats")
        ]
      },
      {
        "id": 2,
        "title": "Community Involvement in Conservation",
        "content":
            "Local communities play an essential role in conservation efforts. "
            "When people benefit economically from protecting wildlife, they are "
            "more likely to support conservation initiatives.\n\n"
            "Ecotourism has been promoted as a way to balance economic development "
            "with environmental protection. However, poor management can damage "
            "fragile ecosystems.\n\n"
            "Effective conservation requires cooperation between governments, "
            "organisations, and local residents.",
        "questions": [
          _tfng(8, "Economic benefits encourage conservation support.", "TRUE"),
          _mcq(9, "What encourages community involvement?",
              ["Punishment", "Economic benefits", "Technology", "Laws only"], "Economic benefits"),
          _sentence(10, "Ecotourism can support wildlife ________.", "conservation"),
          _tfng(11, "All tourism benefits the environment.", "FALSE"),
          _mcq(12, "Poor management of tourism can cause?",
              ["Protection", "Damage", "Education", "Growth"], "Damage"),
          _tfng(13, "Community cooperation is necessary.", "TRUE")
        ]
      },
      {
        "id": 3,
        "title": "Future Conservation Strategies",
        "content":
            "Modern conservation increasingly relies on technology. Satellite tracking "
            "and data analysis allow scientists to monitor species and detect changes "
            "in ecosystems.\n\n"
            "However, technology alone is insufficient. Long-term success depends on "
            "international cooperation and strong political commitment.\n\n"
            "Without sustained support, conservation efforts are unlikely to succeed.",
        "questions": [
          _sentence(14, "Satellite tracking helps ________ species.", "monitor"),
          _tfng(15, "Technology guarantees conservation success.", "FALSE"),
          _mcq(16, "What is essential for long-term success?",
              ["Tourism", "Political commitment", "Urban growth", "Private funding"], "Political commitment"),
          _tfng(17, "International cooperation is required.", "TRUE"),
          _sentence(18, "Data analysis helps detect environmental ________.", "changes"),
          _mcq(19, "Which tool is mentioned?",
              ["Drones", "Satellites", "Robots", "Cameras"], "Satellites"),
          _tfng(20, "Conservation requires sustained support.", "TRUE")
        ]
      }
    ]
  };
}

/* ============================================================
   TEST 3 – HUMAN MEMORY (20 QUESTIONS)
============================================================ */

Map<String, dynamic> _testHumanMemory() {
  return {
    "id": 3,
    "title": "IELTS Academic Reading Test 3",
    "duration": 60,
    "totalQuestions": 20,
    "createdAt": FieldValue.serverTimestamp(),
    "passages": [
      {
        "id": 1,
        "title": "How Human Memory Works",
        "content":
            "Memory enables humans to store, retain, and retrieve information. "
            "Psychologists distinguish between short-term and long-term memory, "
            "each serving different cognitive functions.\n\n"
            "Short-term memory holds information for brief periods, while long-term "
            "memory stores knowledge and experiences over extended durations.\n\n"
            "Understanding how memory works is essential for education and learning.",
        "questions": [
          _mcq(1, "What does memory allow humans to do?",
              ["Forget", "Store information", "Sleep", "Communicate"], "Store information"),
          _tfng(2, "Short-term memory stores information permanently.", "FALSE"),
          _sentence(3, "Long-term memory stores knowledge and ________.", "experiences"),
          _tfng(4, "Psychologists study memory processes.", "TRUE"),
          _mcq(5, "Which memory type is temporary?",
              ["Long-term", "Short-term", "Visual", "Emotional"], "Short-term"),
          _tfng(6, "Memory is important for learning.", "TRUE"),
          _sentence(7, "Memory involves storing and ________ information.", "retrieving")
        ]
      },
      {
        "id": 2,
        "title": "Factors Affecting Memory",
        "content":
            "Memory performance is influenced by several factors including attention, "
            "repetition, emotional significance, and sleep.\n\n"
            "Emotionally significant events are often remembered more vividly than "
            "neutral experiences. Sleep also plays a crucial role in memory consolidation.\n\n"
            "Without sufficient sleep, memory formation can be impaired.",
        "questions": [
          _tfng(8, "Emotion affects memory retention.", "TRUE"),
          _mcq(9, "Which factor supports memory consolidation?",
              ["Stress", "Sleep", "Noise", "Distraction"], "Sleep"),
          _sentence(10, "Emotionally charged events are remembered more ________.", "vividly"),
          _tfng(11, "Sleep reduces memory ability.", "FALSE"),
          _mcq(12, "What negatively affects memory?",
              ["Sleep", "Attention", "Stress", "Repetition"], "Stress"),
          _tfng(13, "Repetition influences memory.", "TRUE")
        ]
      },
      {
        "id": 3,
        "title": "Improving Memory",
        "content":
            "Various techniques have been developed to improve memory performance. "
            "Mnemonic devices, visualisation, and spaced repetition are commonly used.\n\n"
            "These methods help organise information and strengthen long-term retention. "
            "However, individual differences mean that effectiveness varies.\n\n"
            "No single technique works equally well for everyone.",
        "questions": [
          _sentence(14, "Mnemonic devices help ________ memory.", "improve"),
          _tfng(15, "One technique works for everyone.", "FALSE"),
          _mcq(16, "Which is a memory improvement technique?",
              ["Reading", "Mnemonic devices", "Sleeping", "Eating"], "Mnemonic devices"),
          _tfng(17, "Individual differences affect effectiveness.", "TRUE"),
          _sentence(18, "Spaced repetition improves long-term ________.", "retention"),
          _mcq(19, "Which is NOT mentioned?",
              ["Visualisation", "Mnemonics", "Spaced repetition", "Medication"], "Medication"),
          _tfng(20, "Memory can be trained.", "TRUE")
        ]
      }
    ]
  };
}
/* ============================================================
   EXPLANATION + EVIDENCE SEEDING
============================================================ */

Map<String, dynamic> _extractEvidence({
  required String passage,
  required String answer,
}) {
  final lowerPassage = passage.toLowerCase();
  final lowerAnswer = answer.toLowerCase();

  int index = lowerPassage.indexOf(lowerAnswer);

  // Nếu không tìm thấy keyword → fallback lấy câu đầu
  if (index == -1) {
    final end = passage.indexOf('.');
    return {
      "text": passage.substring(0, end + 1),
      "start": 0,
      "end": end + 1,
    };
  }

  int start = index;
  int end = index + answer.length;

  // Mở rộng ra đầu câu
  while (start > 0 &&
      passage[start] != '.' &&
      passage[start] != '\n') {
    start--;
  }

  // Mở rộng ra cuối câu
  while (end < passage.length &&
      passage[end] != '.' &&
      passage[end] != '\n') {
    end++;
  }

  return {
    "text": passage.substring(start, end + 1).trim(),
    "start": start,
    "end": end + 1,
  };
}

String _generateExplanation({
  required String type,
  required String question,
  required String answer,
  required String evidenceText,
}) {
  switch (type) {
    case "MCQ":
      return
          "The passage directly addresses this question. "
          "The correct option is supported by the following sentence:\n\n"
          "\"$evidenceText\"\n\n"
          "This information matches the requirement of the question, while the other options "
          "are not supported by the passage.";

    case "TFNG":
      if (answer == "TRUE") {
        return
            "The statement is TRUE because the passage explicitly confirms this idea. "
            "The evidence states:\n\n"
            "\"$evidenceText\"";
      } else if (answer == "FALSE") {
        return
            "The statement is FALSE because it contradicts the information in the passage. "
            "According to the text:\n\n"
            "\"$evidenceText\"";
      } else {
        return
            "The statement is NOT GIVEN because the passage does not mention this information. "
            "There is no evidence in the text to confirm or contradict the statement.";
      }

    case "SENTENCE":
      return
          "The missing word can be identified directly from the passage. "
          "The relevant part of the text states:\n\n"
          "\"$evidenceText\"\n\n"
          "This confirms the correct completion of the sentence.";

    default:
      return "Explanation not available.";
  }
}

Map<String, dynamic> _attachExplainAndEvidence(
    Map<String, dynamic> test) {
  for (final passage in test['passages']) {
    final String content = passage['content'];

    for (final q in passage['questions']) {
      final evidence = _extractEvidence(
        passage: content,
        answer: q['answer'],
      );

      q['evidence'] = evidence;

      q['explanation'] = _generateExplanation(
        type: q['type'],
        question: q['question'],
        answer: q['answer'],
        evidenceText: evidence['text'],
      );
    }
  }
  return test;
}


/* ============================================================
   HELPERS
============================================================ */

Map<String, dynamic> _mcq(int id, String q, List<String> opts, String ans) => {
      "id": id,
      "type": "MCQ",
      "question": q,
      "options": opts,
      "answer": ans
    };

Map<String, dynamic> _tfng(int id, String q, String ans) => {
      "id": id,
      "type": "TFNG",
      "question": q,
      "answer": ans
    };

Map<String, dynamic> _sentence(int id, String q, String ans) => {
      "id": id,
      "type": "SENTENCE",
      "question": q,
      "answer": ans
    };

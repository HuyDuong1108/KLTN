import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await seedListeningTests();

  debugPrint("✅ LISTENING DATA SEEDED WITH ANSWERS");
}

/// =================================================
/// 🔥 SEED ALL LISTENING TESTS
/// =================================================
Future<void> seedListeningTests() async {
  final firestore = FirebaseFirestore.instance;

  final tests = [listeningTest1(), listeningTest2(), listeningTest3()];

  for (final test in tests) {
    await firestore.collection('listening_tests').doc(test['id']).set(test);
  }
}

/// =================================================
/// 🎧 LISTENING TEST 1
/// =================================================
Map<String, dynamic> listeningTest1() {
  return {
    "id": "test_1",
    "title": "IELTS Listening Test 1",
    "duration": 30,
    "totalQuestions": 40,
    "audioUrl": "https://example.com/audio/test1.mp3",
    "sections": [
      sectionInput(1, [
        qInput("Customer name", "john smith"),
        qInput("Telephone number", "0798456123"),
        qInput("Type of accommodation", "apartment"),
        qInput("Length of stay", "six months"),
        qInput("Weekly rent", "250"),
        qInput("Preferred location", "city centre"),
        qInput("Parking requirement", "yes"),
        qInput("Furnished or unfurnished", "furnished"),
        qInput("Move-in date", "1st september"),
        qInput("Special requests", "near transport"),
      ]),
      sectionMCQ(2, [
        qMCQ("What is the main purpose of the talk?", [
          "To provide information about a new facility",
          "To introduce new staff members",
          "To explain examination rules",
        ], 0),
        qMCQ("Which building will be renovated first?", [
          "The main library",
          "The sports centre",
          "The student cafeteria",
        ], 1),
        qMCQ("What time does the tour begin?", [
          "At nine o’clock",
          "At half past ten",
          "At one o’clock",
        ], 1),
        qMCQ("Where can visitors get more information?", [
          "At the reception desk",
          "On the university website",
          "From student services",
        ], 1),
        qMCQ("Which facility is currently closed?", [
          "The swimming pool",
          "The computer laboratory",
          "The car park",
        ], 0),
        qMCQ("Who is the talk aimed at?", [
          "New international students",
          "Teaching staff",
          "Local residents",
        ], 0),
        qMCQ("Why was the event postponed?", [
          "Due to bad weather",
          "Because of scheduling issues",
          "Owing to low attendance",
        ], 1),
        qMCQ("What is required for registration?", [
          "Completing an online form",
          "Submitting documents in person",
          "Paying a registration fee",
        ], 0),
        qMCQ("How long will the tour last?", [
          "About one hour",
          "Nearly two hours",
          "Over three hours",
        ], 1),
        qMCQ("Where will participants meet?", [
          "At the main entrance hall",
          "Outside the administration building",
          "Near the campus café",
        ], 0),
      ]),
      sectionMCQ(3, [
        qMCQ("What are the students mainly discussing?", [
          "Their research topic",
          "The assignment deadline",
          "The presentation format",
        ], 0),
        qMCQ("Why does Emma disagree with the proposal?", [
          "It would be too expensive",
          "It is not practical",
          "It lacks sufficient evidence",
        ], 2),
        qMCQ("What does the tutor recommend?", [
          "Changing the research topic",
          "Collecting more data",
          "Reducing the project scope",
        ], 1),
        qMCQ("Who will analyse the data?", ["Emma", "Mark", "The tutor"], 1),
        qMCQ("What is the main problem they face?", [
          "Limited time",
          "Lack of resources",
          "Unclear instructions",
        ], 0),
        qMCQ("Which approach is preferred?", [
          "Quantitative analysis",
          "Qualitative interviews",
          "A mixed-method approach",
        ], 2),
        qMCQ("When is the deadline?", [
          "Next Monday",
          "In two weeks",
          "At the end of the semester",
        ], 1),
        qMCQ("Who will contact the supervisor?", [
          "Emma",
          "Mark",
          "Both students",
        ], 2),
        qMCQ("What resources are needed?", [
          "Library journals",
          "Survey software",
          "Laboratory equipment",
        ], 1),
        qMCQ("What decision is made?", [
          "To change the topic",
          "To submit a draft early",
          "To collect more data",
        ], 2),
      ]),

      sectionInput(4, [
        qInput("Topic of the lecture", "climate change"),
        qInput("Main research method", "data analysis"),
        qInput("Key environmental factor", "temperature"),
        qInput("Time period studied", "twenty years"),
        qInput("Primary cause", "human activity"),
        qInput("Effect on wildlife", "habitat loss"),
        qInput("Impact on humans", "health risks"),
        qInput("Proposed solution", "reduce emissions"),
        qInput("Government involvement", "policy reform"),
        qInput("Future outlook", "continued warming"),
      ]),
    ],
  };
}

/// =================================================
/// 🎧 LISTENING TEST 2
/// =================================================
Map<String, dynamic> listeningTest2() {
  return {
    "id": "test_2",
    "title": "IELTS Listening Test 2",
    "duration": 30,
    "totalQuestions": 40,
    "audioUrl": "https://example.com/audio/test2.mp3",
    "sections": [
      sectionInput(1, [
        qInput("Applicant full name", "sarah jones"),
        qInput("Contact email", "sarahj@email.com"),
        qInput("Course selected", "business management"),
        qInput("Study duration", "three years"),
        qInput("Start date", "october"),
        qInput("Accommodation preference", "shared flat"),
        qInput("Meal option", "vegetarian"),
        qInput("Previous experience", "two years"),
        qInput("Payment method", "credit card"),
        qInput("Additional comments", "part-time work"),
      ]),
      sectionMCQ(2, [
        qMCQ("What is the purpose of the announcement?", [
          "To explain changes to public transport",
          "To advertise a new service",
          "To cancel scheduled classes",
        ], 0),
        qMCQ("Which service will be unavailable?", [
          "Library printing",
          "Student bus",
          "Online registration",
        ], 1),
        qMCQ("How often does the bus run?", [
          "Every ten minutes",
          "Every half hour",
          "Once an hour",
        ], 1),
        qMCQ("What time does the library close?", [
          "At six o’clock",
          "At eight o’clock",
          "At ten o’clock",
        ], 2),
        qMCQ("Where can forms be collected?", [
          "From the reception desk",
          "At the library counter",
          "Online",
        ], 0),
        qMCQ("Who should attend the meeting?", [
          "All new students",
          "Final-year students",
          "Teaching staff only",
        ], 1),
        qMCQ("Why is the rule introduced?", [
          "To improve safety",
          "To save costs",
          "To reduce noise",
        ], 0),
        qMCQ("What is the penalty?", [
          "A written warning",
          "A monetary fine",
          "Temporary suspension",
        ], 2),
        qMCQ("Which option is recommended?", [
          "Online submission",
          "Paper application",
          "Email registration",
        ], 0),
        qMCQ("Where is the exit located?", [
          "Next to the cafeteria",
          "Behind the library",
          "Opposite the main gate",
        ], 2),
      ]),
      sectionMCQ(3, [
        qMCQ("What are the students mainly discussing?", [
          "Their research topic",
          "The assignment deadline",
          "The presentation format",
        ], 0),
        qMCQ("Why does Emma disagree with the proposal?", [
          "It would be too expensive",
          "It is not practical",
          "It lacks sufficient evidence",
        ], 2),
        qMCQ("What does the tutor recommend?", [
          "Changing the research topic",
          "Collecting more data",
          "Reducing the project scope",
        ], 1),
        qMCQ("Who will analyse the data?", ["Emma", "Mark", "The tutor"], 1),
        qMCQ("What is the main problem they face?", [
          "Limited time",
          "Lack of resources",
          "Unclear instructions",
        ], 0),
        qMCQ("Which approach is preferred?", [
          "Quantitative analysis",
          "Qualitative interviews",
          "A mixed-method approach",
        ], 2),
        qMCQ("When is the deadline?", [
          "Next Monday",
          "In two weeks",
          "At the end of the semester",
        ], 1),
        qMCQ("Who will contact the supervisor?", [
          "Emma",
          "Mark",
          "Both students",
        ], 2),
        qMCQ("What resources are needed?", [
          "Library journals",
          "Survey software",
          "Laboratory equipment",
        ], 1),
        qMCQ("What decision is made?", [
          "To change the topic",
          "To submit a draft early",
          "To collect more data",
        ], 2),
      ]),

      sectionInput(4, [
        qInput("Lecture subject", "urban planning"),
        qInput("Definition discussed", "sustainable cities"),
        qInput("Key statistic", "sixty percent"),
        qInput("Case study location", "singapore"),
        qInput("Major finding", "reduced congestion"),
        qInput("Supporting evidence", "survey data"),
        qInput("Effect on economy", "job creation"),
        qInput("Suggested improvement", "public transport"),
        qInput("Long-term impact", "lower emissions"),
        qInput("Prediction for future", "population growth"),
      ]),
    ],
  };
}

/// =================================================
/// 🎧 LISTENING TEST 3
/// =================================================
Map<String, dynamic> listeningTest3() {
  return {
    "id": "test_3",
    "title": "IELTS Listening Test 3",
    "duration": 30,
    "totalQuestions": 40,
    "audioUrl": "https://example.com/audio/test3.mp3",
    "sections": [
      sectionInput(1, [
        qInput("Participant name", "david lee"),
        qInput("Registration number", "a2045"),
        qInput("Workshop title", "digital marketing"),
        qInput("Session date", "15 july"),
        qInput("Session length", "two hours"),
        qInput("Venue location", "conference hall"),
        qInput("Equipment needed", "laptop"),
        qInput("Experience level", "intermediate"),
        qInput("Group size", "twelve"),
        qInput("Feedback preference", "email"),
      ]),
      sectionMCQ(2, [
        qMCQ("What is the main topic of the talk?", [
          "Online advertising strategies",
          "Traditional marketing methods",
          "Customer relationship management",
        ], 0),
        qMCQ("Which option is cheapest?", [
          "Monthly subscription",
          "Annual membership",
          "One-time payment",
        ], 1),
        qMCQ("What time does the event finish?", [
          "At four o’clock",
          "At five thirty",
          "At seven",
        ], 1),
        qMCQ("Where is parking available?", [
          "In the underground car park",
          "On the street nearby",
          "Behind the building",
        ], 0),
        qMCQ("Who is responsible for safety?", [
          "The event organiser",
          "The security team",
          "The venue manager",
        ], 1),
        qMCQ("Why is the change necessary?", [
          "To improve efficiency",
          "To reduce costs",
          "To meet regulations",
        ], 2),
        qMCQ("What will be provided?", [
          "Printed materials",
          "Refreshments",
          "Online resources",
        ], 1),
        qMCQ("Which activity is optional?", [
          "Group discussion",
          "Final assessment",
          "Networking session",
        ], 2),
        qMCQ("What should attendees bring?", [
          "Personal identification",
          "Writing materials",
          "Their own laptop",
        ], 2),
        qMCQ("How can questions be asked?", [
          "During the presentation",
          "At the end of the session",
          "Via email afterwards",
        ], 1),
      ]),
      sectionMCQ(3, [
        qMCQ("What are the students mainly discussing?", [
          "Their research topic",
          "The assignment deadline",
          "The presentation format",
        ], 0),
        qMCQ("Why does Emma disagree with the proposal?", [
          "It would be too expensive",
          "It is not practical",
          "It lacks sufficient evidence",
        ], 2),
        qMCQ("What does the tutor recommend?", [
          "Changing the research topic",
          "Collecting more data",
          "Reducing the project scope",
        ], 1),
        qMCQ("Who will analyse the data?", ["Emma", "Mark", "The tutor"], 1),
        qMCQ("What is the main problem they face?", [
          "Limited time",
          "Lack of resources",
          "Unclear instructions",
        ], 0),
        qMCQ("Which approach is preferred?", [
          "Quantitative analysis",
          "Qualitative interviews",
          "A mixed-method approach",
        ], 2),
        qMCQ("When is the deadline?", [
          "Next Monday",
          "In two weeks",
          "At the end of the semester",
        ], 1),
        qMCQ("Who will contact the supervisor?", [
          "Emma",
          "Mark",
          "Both students",
        ], 2),
        qMCQ("What resources are needed?", [
          "Library journals",
          "Survey software",
          "Laboratory equipment",
        ], 1),
        qMCQ("What decision is made?", [
          "To change the topic",
          "To submit a draft early",
          "To collect more data",
        ], 2),
      ]),

      sectionInput(4, [
        qInput("Lecture title", "data analytics"),
        qInput("Research objective", "improve accuracy"),
        qInput("Main hypothesis", "automation helps"),
        qInput("Sample size", "five hundred"),
        qInput("Key variable", "response time"),
        qInput("Observed trend", "steady increase"),
        qInput("Limitation", "small dataset"),
        qInput("Practical application", "business decisions"),
        qInput("Policy implication", "data privacy"),
        qInput("Conclusion", "further research"),
      ]),
    ],
  };
}

/// =================================================
/// 🧩 HELPERS
/// =================================================
Map<String, dynamic> sectionInput(
  int section,
  List<Map<String, dynamic>> questions,
) {
  return {
    "section": section,
    "instruction":
        "Questions ${(section - 1) * 10 + 1}–${section * 10}\nComplete the form below.\nWrite NO MORE THAN TWO WORDS AND/OR A NUMBER.",
    "questions": List.generate(questions.length, (i) {
      return {"number": (section - 1) * 10 + i + 1, ...questions[i]};
    }),
  };
}

Map<String, dynamic> sectionMCQ(
  int section,
  List<Map<String, dynamic>> questions,
) {
  return {
    "section": section,
    "instruction":
        "Questions ${(section - 1) * 10 + 1}–${section * 10}\nChoose the correct answer.",
    "questions": List.generate(questions.length, (i) {
      return {"number": (section - 1) * 10 + i + 1, ...questions[i]};
    }),
  };
}

Map<String, dynamic> qInput(String question, String answer) {
  return {
    "question": question,
    "answerType": "input",
    "correctAnswer": answer.toLowerCase(),
  };
}

Map<String, dynamic> qMCQ(
  String question,
  List<String> options,
  int correctIndex,
) {
  return {
    "question": question,
    "answerType": "mcq",
    "options": options,
    "correctAnswer": correctIndex,
  };
}

import 'package:flutter/material.dart';
import 'listening_result_page.dart';

class ListeningTestPage extends StatelessWidget {
  const ListeningTestPage({super.key});

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          "IELTS Listening Test 1",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "29:45",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          )
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          _audioPlayer(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ================= SECTION 1 =================
                _sectionHeader(
                  title: "Section 1",
                  description:
                      "Questions 1–10\nComplete the form below.\nWrite NO MORE THAN TWO WORDS AND/OR A NUMBER.",
                ),

                _questionInput(1, "Customer name"),
                _questionInput(2, "Telephone number"),
                _questionInput(3, "Type of accommodation"),
                _questionInput(4, "Length of stay"),
                _questionInput(5, "Weekly rent"),
                _questionInput(6, "Preferred area"),
                _questionInput(7, "Parking required"),
                _questionInput(8, "Furnished or unfurnished"),
                _questionInput(9, "Move-in date"),
                _questionInput(10, "Special requests"),

                const SizedBox(height: 36),

                // ================= SECTION 2 =================
                _sectionHeader(
                  title: "Section 2",
                  description:
                      "Questions 11–20\nChoose the correct answer.",
                ),

                _questionMCQ(
                  11,
                  "What is the main purpose of the talk?",
                  [
                    "A. To describe a public facility",
                    "B. To give directions around campus",
                    "C. To explain safety regulations",
                  ],
                ),

                _questionMCQ(
                  12,
                  "Which building will be renovated first?",
                  [
                    "A. The library",
                    "B. The sports centre",
                    "C. The cafeteria",
                  ],
                ),

                _questionMCQ(
                  13,
                  "What time does the tour begin?",
                  [
                    "A. 9:00 am",
                    "B. 10:30 am",
                    "C. 1:00 pm",
                  ],
                ),

                _questionMCQ(
                  14,
                  "Where can students get additional information?",
                  [
                    "A. Reception desk",
                    "B. University website",
                    "C. Student services office",
                  ],
                ),

                _questionMCQ(
                  15,
                  "Which facility is temporarily closed?",
                  [
                    "A. Swimming pool",
                    "B. Computer lab",
                    "C. Parking area",
                  ],
                ),

                const SizedBox(height: 36),

                // ================= SECTION 3 =================
                _sectionHeader(
                  title: "Section 3",
                  description:
                      "Questions 21–30\nChoose the correct answer.",
                ),

                _questionMCQ(
                  21,
                  "What is the main topic of the students’ discussion?",
                  [
                    "A. Research methodology",
                    "B. Assignment deadline",
                    "C. Presentation format",
                  ],
                ),

                _questionMCQ(
                  22,
                  "Why does Emma disagree with the proposal?",
                  [
                    "A. It is too expensive",
                    "B. It is not practical",
                    "C. It lacks evidence",
                  ],
                ),

                _questionMCQ(
                  23,
                  "What does the tutor suggest?",
                  [
                    "A. Changing the research topic",
                    "B. Collecting more data",
                    "C. Reducing the project scope",
                  ],
                ),

                _questionMCQ(
                  24,
                  "Which part will Mark be responsible for?",
                  [
                    "A. Data analysis",
                    "B. Literature review",
                    "C. Final presentation",
                  ],
                ),

                _questionMCQ(
                  25,
                  "What will they do next?",
                  [
                    "A. Meet again next week",
                    "B. Submit a draft",
                    "C. Conduct interviews",
                  ],
                ),

                const SizedBox(height: 36),

                // ================= SECTION 4 =================
                _sectionHeader(
                  title: "Section 4",
                  description:
                      "Questions 31–40\nComplete the notes below.",
                ),

                _questionInput(31, "Main topic of the lecture"),
                _questionInput(32, "Key factor affecting climate"),
                _questionInput(33, "Average temperature increase"),
                _questionInput(34, "Time period studied"),
                _questionInput(35, "Primary cause of change"),
                _questionInput(36, "Effect on wildlife"),
                _questionInput(37, "Impact on human health"),
                _questionInput(38, "Proposed solution"),
                _questionInput(39, "Government response"),
                _questionInput(40, "Future prediction"),
              ],
            ),
          ),
        ],
      ),

      // ================= BOTTOM BAR =================
      bottomNavigationBar: _bottomBar(context),
    );
  }

  // ================= AUDIO PLAYER =================
  Widget _audioPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "You will hear the recording ONCE only",
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.play_circle_fill,
                  size: 40, color: primaryBlue),
              SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.35,
                  minHeight: 6,
                  backgroundColor: Color(0xFFE3F2FD),
                  valueColor:
                      AlwaysStoppedAnimation(primaryBlue),
                ),
              ),
              SizedBox(width: 12),
              Text("02:15"),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SECTION HEADER =================
  Widget _sectionHeader({
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    );
  }

  // ================= INPUT QUESTION =================
  Widget _questionInput(int number, String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. $question",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: "Write NO MORE THAN TWO WORDS",
              filled: true,
              fillColor: const Color(0xFFF5FAFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MULTIPLE CHOICE =================
  Widget _questionMCQ(
    int number,
    String question,
    List<String> options,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. $question",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...options.map(
            (e) => RadioListTile(
              value: e,
              groupValue: null,
              onChanged: (_) {},
              title: Text(e),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================
  Widget _bottomBar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      children: [
        // ===== PROGRESS =====
        const Text(
          "Question 3 / 40",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),

        const Spacer(),

        // ===== SUBMIT BUTTON =====
        ElevatedButton.icon(
          onPressed: () {
            _showSubmitDialog(context);
          },
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          label: const Text(
            "Submit Test",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    ),
  );
}
void _showSubmitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Submit Test"),
      content: const Text(
        "Are you sure you want to submit your answers?\nYou cannot change them after submission.",
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);

            // TODO: Navigate to Result Page
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ListeningResultPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
          ),
          child: const Text("Submit", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

}

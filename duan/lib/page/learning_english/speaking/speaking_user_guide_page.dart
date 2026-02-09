import 'package:flutter/material.dart';

class SpeakingUserGuidePage extends StatelessWidget {
  const SpeakingUserGuidePage({super.key});

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          "Hướng dẫn sử dụng Speaking",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStep(
            context,
            stepNumber: "1",
            icon: Icons.phone_android,
            title: "Mở ứng dụng",
            description:
                "Từ màn hình chính → Chọn tab **Learning English** → Nhấn vào **Speaking**\n\nBạn sẽ thấy 3 tab: Practice / Progress / History",
            tips: [
              "Tab Practice: Luyện phát âm ngay",
              "Tab Progress: Xem biểu đồ tiến bộ",
              "Tab History: Xem lại các lần luyện trước",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "2",
            icon: Icons.category,
            title: "Chọn Practice Mode",
            description:
                "Trong tab **Practice**, bạn sẽ thấy 3 chế độ luyện tập:\n\n• **Pronunciation Practice** ← Chọn cái này\n• IELTS Speaking Test\n• AI Speaking Partner",
            tips: [
              "Pronunciation Practice: Luyện phát âm chi tiết với AI feedback",
              "IELTS Speaking Test: Thi thử IELTS Speaking",
              "AI Speaking Partner: Trò chuyện với AI như người thật",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "3",
            icon: Icons.school,
            title: "Chọn Category (Danh mục)",
            description:
                "Chọn 1 trong 3 category để luyện tập:\n\n**Individual Sounds** - Luyện âm đơn khó (th, r, v, w...)\n**Word Stress** - Trọng âm từ (PHOto vs phoTOgraphy)\n**Sentence Intonation** - Ngữ điệu câu (lên xuống)",
            tips: [
              "Nhấn vào category → App tự động sinh câu luyện bằng Gemini AI",
              "Câu luyện phù hợp với level IELTS của bạn",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "4",
            icon: Icons.headset,
            title: "Nghe câu mẫu",
            description:
                "Nhấn nút **Listen** (icon 🔊) → Nghe cách phát âm chuẩn\n\nLắng nghe kỹ:\n• Cách đọc từng từ\n• Trọng âm ở đâu\n• Ngữ điệu câu lên xuống",
            tips: [
              "Nghe nhiều lần cho đến khi thuộc",
              "Chú ý phần nào khó phát âm",
              "Tốc độ đọc chậm (0.45x) để dễ nghe",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "5",
            icon: Icons.mic,
            title: "Ghi âm (Recording)",
            description:
                "**Bước 1:** Nhấn nút **Record** (icon 🎙️ màu đỏ)\n**Bước 2:** Đọc to và rõ ràng theo câu mẫu\n**Bước 3:** Nhấn **Stop** hoặc đợi tự động dừng sau 10 giây\n\n⏱️ Thời gian ghi: Tối đa 10 giây",
            tips: [
              "Đọc ở nơi yên tĩnh, không ồn",
              "Cầm điện thoại gần miệng (15-20cm)",
              "Đọc tự nhiên, không quá nhanh hay chậm",
              "Phát âm rõ ràng từng từ",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "6",
            icon: Icons.cloud_upload,
            title: "Xử lý (Processing)",
            description:
                "Sau khi dừng ghi âm, hệ thống sẽ:\n\n1️⃣ **Uploading audio...** (2-3 giây)\n   → Gửi file âm thanh lên Google Cloud\n\n2️⃣ **Analyzing pronunciation...** (5-7 giây)\n   → AI phân tích phát âm với Gemini 2.0",
            tips: [
              "Cần kết nối internet (Wi-Fi hoặc 4G/5G)",
              "Đợi 5-10 giây để AI phân tích",
              "Không tắt app trong lúc xử lý",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "7",
            icon: Icons.analytics,
            title: "Xem kết quả nhanh",
            description:
                "Sau khi phân tích xong, bạn sẽ thấy:\n\n**Band Score** (1.0-9.0) - Điểm IELTS của bạn\n**Overall Score** (0-100) - Điểm tổng\n**Error Count** - Số lỗi phát âm\n**Quick Tips** - Gợi ý cải thiện ngắn gọn",
            tips: [
              "Band 7.0+ = Rất tốt ✅",
              "Band 5.5-6.5 = Trung bình, cần cải thiện",
              "Band <5.0 = Cần luyện nhiều hơn",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "8",
            icon: Icons.visibility,
            title: "Xem chi tiết (Review Page)",
            description:
                "Nhấn **View Detailed Feedback** để xem chi tiết:\n\n📝 **Transcript có màu:**\n• Đỏ = Sai nghiêm trọng (severity 8-10)\n• Vàng = Sai trung bình (severity 5-7)\n• Xanh = Sai nhẹ (severity 1-4)\n\n👆 **Tap vào từ** → Nghe lại + xem lỗi IPA + tip cụ thể",
            tips: [
              "Xem bảng lỗi chi tiết (Error Table)",
              "Filter theo loại lỗi (stress/vowel/consonant...)",
              "Đọc feedback tiếng Việt hoặc English (toggle)",
              "Lưu ý phần 'Improvement Focus' - lỗi hay mắc nhất",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "9",
            icon: Icons.trending_up,
            title: "Xem tiến độ (Progress Tab)",
            description:
                "Vào tab **Progress** để theo dõi:\n\n📊 **Band Score Chart** - Đường line chart tiến bộ qua các lần luyện\n📈 **Error Breakdown** - Loại lỗi nào hay mắc nhất (stress, vowel, consonant...)\n🏆 **Achievements** - Huy hiệu khi đạt milestone",
            tips: [
              "Luyện đều đặn mỗi ngày → Band score tăng dần",
              "Tập trung vào loại lỗi hay mắc nhất",
              "Đạt 10 sessions → Nhận huy hiệu 🔥",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "10",
            icon: Icons.history,
            title: "Xem lịch sử (History Tab)",
            description:
                "Tab **History** → Danh sách tất cả session đã luyện\n\nMỗi session hiển thị:\n• Thời gian luyện\n• Band score\n• Category\n• Số lỗi\n\nNhấn vào session → Mở lại review page",
            tips: [
              "So sánh band score giữa các lần luyện",
              "Xem lại lỗi cũ để tránh lặp lại",
              "Luyện lại câu cũ để cải thiện",
            ],
          ),
          _buildStep(
            context,
            stepNumber: "11",
            icon: Icons.repeat,
            title: "Luyện lại & Next Sentence",
            description:
                "Sau khi xem feedback:\n\n• Nhấn **Next Sentence** (bottom bar) → Sinh câu mới\n• Hoặc đổi category → Luyện khía cạnh khác\n• Luyện lại cùng 1 câu → Cải thiện điểm số",
            tips: [
              "Luyện mỗi ngày 10-15 phút = Hiệu quả cao",
              "Đổi category để luyện đa dạng",
              "Ghi chú lỗi hay mắc để tránh lặp lại",
            ],
          ),
          const SizedBox(height: 24),
          _buildTroubleshootingSection(),
          const SizedBox(height: 24),
          _buildAPISetupSection(),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String stepNumber,
    required IconData icon,
    required String title,
    required String description,
    List<String>? tips,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: primaryBlue, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          if (tips != null && tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: primaryBlue, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Tips:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "• ",
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                "Xử lý lỗi thường gặp",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTroubleshootItem(
            "❌ 'No internet connection'",
            "Kiểm tra Wi-Fi hoặc 4G/5G. Cloud API cần internet.",
          ),
          _buildTroubleshootItem(
            "❌ 'Microphone permission denied'",
            "Vào Settings → App Permissions → Enable Microphone.",
          ),
          _buildTroubleshootItem(
            "❌ 'API error: Invalid credentials'",
            "API Key sai hoặc hết hạn. Kiểm tra file .env.",
          ),
          _buildTroubleshootItem(
            "❌ 'No speech detected'",
            "Nói to hơn, đọc rõ hơn, kiểm tra mic điện thoại.",
          ),
          _buildTroubleshootItem(
            "❌ 'Failed to process audio'",
            "Thử lại sau vài giây. Có thể do mạng chậm.",
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, String solution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            problem,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "→ $solution",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildAPISetupSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                "Setup API Keys (Cho Developer)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "📝 File .env (project root):",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "API_KEY=YOUR_GEMINI_API_KEY\nGOOGLE_CLOUD_API_KEY=YOUR_SPEECH_API_KEY",
              style: TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "🔑 Lấy API Keys:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          _buildAPIStep(
            "1",
            "Gemini API",
            "https://aistudio.google.com/apikey",
          ),
          _buildAPIStep(
            "2",
            "Google Cloud Speech",
            "https://console.cloud.google.com/apis/credentials",
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "⚠️ Không commit file .env lên Git! Thêm vào .gitignore",
                    style: TextStyle(fontSize: 13, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIStep(String step, String name, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$step. ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

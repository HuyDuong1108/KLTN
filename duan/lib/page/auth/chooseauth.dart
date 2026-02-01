import 'package:flutter/material.dart';
import 'login.dart';
import 'signin.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDE3A7), // cam nhạt
              Color(0xFFD6EAF8), // xanh nhạt
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo con sóc
            Image.asset(
              "lib/image/logo.png",
              width: 180, // tăng kích thước logo
              height: 180,
            ),
            const SizedBox(height: 30),

            // Tên app
            const Text(
              "LinguaSquirrel",
              style: TextStyle(
                fontSize: 36, // chữ to hơn
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            const Text(
              "Ứng dụng học ngôn ngữ Đông Á",
              style: TextStyle(
                fontSize: 20, // subtitle cũng to hơn
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 60),

            // Nút Create Account
            SizedBox(
              width: 280,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5, // thêm bóng để nổi bật
                ),
                child: const Text(
                  "CREATE ACCOUNT",
                  style: TextStyle(
                    fontSize: 20, // chữ to hơn
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nút Login
            SizedBox(
              width: 280,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "LOG IN",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

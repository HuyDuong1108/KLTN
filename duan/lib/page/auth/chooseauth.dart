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
              Color(0xFFE3F2FD), 
  Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo con sóc
            Image.asset(
              "lib/image/logo.png",
              width: 250, // tăng kích thước logo
              height: 250,
            ),
            const SizedBox(height: 30),

            // Tên app
            const Text(
              "DolphSpeak",
              style: TextStyle(
                fontSize: 36, // chữ to hơn
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            const Text(
              "Học nói tiếng Anh cùng cá heo",
              style: TextStyle(
                fontSize: 20, // subtitle cũng to hơn
                color: Color(0xFF607D8B),
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
  backgroundColor: Color(0xFF42A5F5),
  elevation: 5,
  shadowColor: const Color(0x554FC3F7), // xanh cá heo mờ
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
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
  backgroundColor: const Color(0xFF4FC3F7),
  elevation: 5,
  shadowColor: const Color(0x554FC3F7), // xanh cá heo mờ
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
),

                child: const Text(
                  "LOG IN",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 233, 238, 240),

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

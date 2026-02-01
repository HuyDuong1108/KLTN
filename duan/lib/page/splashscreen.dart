import 'package:flutter/material.dart';
import 'auth/chooseauth.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800), // thời gian hiệu ứng
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // hiệu ứng slide lên
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0, 1), // từ dưới màn hình
              end: Offset.zero,          // về vị trí bình thường
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,   // mượt mà
            ));

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'lib/image/Splash_Screen.jpg',
          fit: BoxFit.cover, // cho full màn hình
        ),
      ),
    );
  }
}
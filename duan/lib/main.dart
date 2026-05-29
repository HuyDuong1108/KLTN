import 'package:flutter/material.dart';
import 'page/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'data/backend_launcher.dart';
import 'admin/admin_dashboard.dart';
import 'companion/widgets/floating_companion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await dotenv.load(fileName: ".env"); 

  await dotenv.load(fileName: ".env");
  // await BackendLauncher.ensureStarted(); // cập nhật backend
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansJpTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) {
        return FloatingCompanion(child: child ?? const SizedBox.shrink());
      },
      home: const SplashScreen(),
      // home: const AdminDashboard(), // mở đầu bằng Splash
    );
  }
}

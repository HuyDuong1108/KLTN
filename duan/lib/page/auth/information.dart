import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../layout/layout_main.dart';

class UserInfoPage extends StatefulWidget {
  final String uid;
  const UserInfoPage({super.key, required this.uid});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final nameController = TextEditingController();
  final birthController = TextEditingController();
  String gender = "Male";
  bool loading = false;

  Future<void> saveInfo() async {
    setState(() => loading = true);
    try {
      await FirebaseFirestore.instance.collection("users").doc(widget.uid).set({
        "name": nameController.text.trim(),
        "birthdate": birthController.text.trim(),
        "gender": gender,
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi lưu thông tin: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE1F5FE), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  Image.asset("lib/image/logo.png", width: 200, height: 200),
                  const SizedBox(height: 25),
                  const Text(
                    "Complete Your Profile",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x334FC3F7),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: // Full Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Color(0xFF4FC3F7),
                        ),
                        hintText: "Full Name",
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFB3E5FC), // xanh nhạt
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF4FC3F7), // xanh cá heo
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x334FC3F7),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: // Birthdate
                    TextField(
                      controller: birthController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: Color(0xFF4FC3F7),
                        ),
                        hintText: "Birthdate (dd/mm/yyyy)",
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFB3E5FC), // xanh nhạt
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF4FC3F7), // xanh cá heo
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Gender
                  // Gender
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x334FC3F7), // shadow xanh nhạt
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: gender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFB3E5FC),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF4FC3F7),
                            width: 2,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF4FC3F7),
                      ),
                      items: ["Male", "Female", "Other"]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.wc_outlined,
                                    color: Color(0xFF4FC3F7),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(e),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => gender = val!),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : saveInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4FC3F7), // xanh cá heo
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "SAVE & CONTINUE",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

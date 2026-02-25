import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String uid;
  const EditProfilePage({super.key, required this.uid});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final birthController = TextEditingController();
  String gender = "Male";

  bool loading = false;
  bool fetching = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        nameController.text = data?["name"] ?? "";
        birthController.text = data?["birthdate"] ?? "";
        gender = data?["gender"] ?? "Male";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải dữ liệu: $e")),
      );
    } finally {
      setState(() => fetching = false);
    }
  }

  Future<void> _saveInfo() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.uid)
          .update({
        "name": nameController.text.trim(),
        "birthdate": birthController.text.trim(),
        "gender": gender,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully 🎉")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF4FC3F7)),
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Color(0xFF1565C0)),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: fetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4FC3F7),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundImage:
                          AssetImage("lib/image/dung.png"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Name
                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration(
                        "Full Name", Icons.person_outline),
                  ),

                  const SizedBox(height: 18),

                  // Birthdate
                  TextField(
                    controller: birthController,
                    decoration: _inputDecoration(
                        "Birthdate (dd/mm/yyyy)",
                        Icons.calendar_today_outlined),
                  ),

                  const SizedBox(height: 18),

                  // Gender
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: _inputDecoration(
                        "Gender", Icons.wc_outlined),
                    items: ["Male", "Female", "Other"]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => gender = val!),
                  ),

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : _saveInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              "SAVE CHANGES",
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
    );
  }
}
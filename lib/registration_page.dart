import 'package:citicare/otp_verification.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CitiCareRegistrationPage extends StatefulWidget {
  const CitiCareRegistrationPage({super.key});

  @override
  State<CitiCareRegistrationPage> createState() =>
      _CitiCareRegistrationPageState();
}

class _CitiCareRegistrationPageState extends State<CitiCareRegistrationPage> {
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RegExp phoneRegex = RegExp(r'^\+639\d{9}$');

  bool isSenior = false;
  bool isPWD = false;
  bool isSoloParent = false;

  Future<void> registerUser() async {
    String userType = '';
    if (isSenior) userType = 'Senior Citizen';
    if (isPWD) userType = 'PWD';
    if (isSoloParent) userType = 'Solo Parent';

    if (userType.isEmpty ||
        contactController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    if (!phoneRegex.hasMatch(contactController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Enter a valid Philippine number (e.g. +639XXXXXXXXX).')),
      );
      return;
    }

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.4:8080/citicare/users/registration.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contact_info": contactController.text,
          "password": passwordController.text,
          "user_type": userType,
        }),
      );

      Navigator.pop(context); // close loading spinner

      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        // Redirect to OTP page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpVerificationPage(contactInfo: contactController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data['message']}")),
        );
      }
    } catch (e) {
      Navigator.pop(context); // close loading spinner on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(0),
                border: Border(
                  top: BorderSide(color: Colors.green.shade700, width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/logo/main_logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Welcome To CitiCare",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "A Digital QR Code Registration and Real-Time Monitoring System with SMS Notifications for PWDs, Senior Citizens, and Solo Parents",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "We must first verify that it was you.",
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Are you a:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  CheckboxListTile(
                    value: isSenior,
                    onChanged: (val) {
                      setState(() {
                        isSenior = val!;
                        isPWD = false;
                        isSoloParent = false;
                      });
                    },
                    title: const Text("Senior Citizen"),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                  ),
                  CheckboxListTile(
                    value: isPWD,
                    onChanged: (val) {
                      setState(() {
                        isPWD = val!;
                        isSenior = false;
                        isSoloParent = false;
                      });
                    },
                    title: const Text("Person With Disability (PWD)"),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                  ),
                  CheckboxListTile(
                    value: isSoloParent,
                    onChanged: (val) {
                      setState(() {
                        isSoloParent = val!;
                        isSenior = false;
                        isPWD = false;
                      });
                    },
                    title: const Text("Solo Parent"),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Input Information:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      if (value.startsWith('09')) {
                        final converted = value.replaceFirst('09', '+639');
                        contactController.value = TextEditingValue(
                          text: converted,
                          selection:
                              TextSelection.collapsed(offset: converted.length),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "e.g. +639XXXXXXXXX",
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: const Text(
                        "Register Now",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Note: A One-Time-Pin (OTP) will be sent to your preferred contact information.",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
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

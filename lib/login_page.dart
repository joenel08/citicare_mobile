import 'package:citicare/senior/SeniorIncompleteProfilePage.dart';
import 'package:citicare/senior/view_submitted_info.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'registration_page.dart';
import 'senior/dashboard_senior.dart';
import 'pwd/dashboard_pwd.dart';
import 'solo/dashboard_solo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginUser() async {
    final contact = contactController.text.trim();
    final password = passwordController.text.trim();

    if (contact.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter contact number and password.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://192.168.100.4:8080/citicare/users/login.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contact_info": contact,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => isLoading = false);

      if (data['status'] == 'success') {
        if (data['verified'] == 1) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', data['id']);
          await prefs.setString('user_type', data['user_type']);
          await prefs.setString('contact_info', contact);

          if (data['user_type'] == 'Senior Citizen') {
            if (data['has_profile'] == true && data['profile'] != null) {
              // Save full profile to session
              Map profile = data['profile'];
              for (var key in profile.keys) {
                final value = profile[key];
                if (value != null) {
                  await prefs.setString('profile_$key', value.toString());
                }
              }

              // Get is_verified from SharedPreferences (it's stored as string)
              String? verifiedStr = prefs.getString("profile_is_verified");
              int is_verified = int.tryParse(verifiedStr ?? "0") ?? 0;

              if (is_verified == 0) {
                // Redirect to View Submitted Information page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewSubmittedInfoPage()),
                );
                return;
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SeniorDashboard(userId: data['id'])),
                );
              }

              // Redirect to dashboard
            } else {
              // Redirect to incomplete profile page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const SeniorIncompleteProfilePage()),
              );
            }
          }

          // TODO: Handle PWD & Solo Parent user types as needed
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not verified!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      body: SafeArea(
        child: Center(
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
                  children: [
                    Image.asset('assets/logo/main_logo.png', height: 80),
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome Back to CitiCare",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "e.g. +639XXXXXXXXX",
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Placeholder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Feature coming soon!')),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CitiCareRegistrationPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register here",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

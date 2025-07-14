import 'package:citicare/senior/senior_application_form.dart';
import 'package:flutter/material.dart';

class SeniorIncompleteProfilePage extends StatelessWidget {
  const SeniorIncompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF), // Body background color
      appBar: AppBar(
        title: Image.asset(
          'assets/logo/citicare_white.png',
          height: 28,
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Card background color
              border: Border(
                top: BorderSide(
                  color: Colors.green.shade700,
                  width: 2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Profile Incomplete",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You haven't completed your registration information yet. Please apply to continue.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SeniorApplicationForm()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // No radius
                    ),
                  ),
                  child: const Text(
                    "Apply Here!",
                    style: TextStyle(color: Colors.white), // White text
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

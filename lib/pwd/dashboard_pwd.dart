import 'package:flutter/material.dart';

class PwdDashboard extends StatelessWidget {
  final int userId;
  const PwdDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PWD Dashboard")),
      body: Center(child: Text("Welcome PWD, ID: $userId")),
    );
  }
}

import 'package:flutter/material.dart';

class SoloDashboard extends StatelessWidget {
  final int userId;
  const SoloDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Solo Parent Dashboard")),
      body: Center(child: Text("Welcome Solo Parent, ID: $userId")),
    );
  }
}

import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final int userId;
  final String userType;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CitiCare Dashboard'),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Text(
          'Welcome User ID: $userId\nType: $userType',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

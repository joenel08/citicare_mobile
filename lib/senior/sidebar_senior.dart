import 'package:flutter/material.dart';

class SeniorSidebar extends StatelessWidget {
  final Function(String) onNavigate;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const SeniorSidebar({
    super.key,
    required this.onNavigate,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: isCollapsed ? 70 : 250,
      duration: const Duration(milliseconds: 200),
      color: const Color(0xFF103c1d),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFF3ECB6C),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Image.asset(
                      'assets/logo/cc_white.png',
                      height: 30,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!isCollapsed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Senior Citizen Account',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 20),
          buildMenuItem(Icons.dashboard, "Dashboard"),
          if (!isCollapsed) sectionTitle("PUBLICATION"),
          buildMenuItem(Icons.article, "News"),
          buildMenuItem(Icons.announcement, "Announcements"),
          buildMenuItem(Icons.app_registration, "Attendance"),
          if (!isCollapsed) sectionTitle("ACTION"),
          buildMenuItem(Icons.settings, "Manage Profile"),
          buildMenuItem(Icons.logout, "Logout"),
        ],
      ),
    );
  }

  Widget buildMenuItem(IconData icon, String title) {
    return InkWell(
      onTap: () => onNavigate(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white70, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}

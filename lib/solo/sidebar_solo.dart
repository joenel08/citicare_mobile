import 'package:citicare/dashboard_page.dart';
import 'package:citicare/senior/dashboard_senior.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citicare/senior/news_page.dart';
import 'package:citicare/senior/announcements_page.dart';
// import 'package:citicare/senior/attendance_page.dart';
// import 'package:citicare/senior/manage_profile_page.dart';
import 'package:citicare/login_page.dart';

class SoloSidebar extends StatefulWidget {
  final Function(String) onNavigate;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const SoloSidebar({
    super.key,
    required this.onNavigate,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  State<SoloSidebar> createState() => _SoloSidebarState();
}

class _SoloSidebarState extends State<SoloSidebar> {
  String fullname = "";
  int? userID;
  // String userType = "";

  @override
  void initState() {
    super.initState();
    _loadFullname();
  }

  Future<void> _loadFullname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String firstName = prefs.getString('profile_first_name') ?? '';
    String lastName = prefs.getString('profile_last_name') ?? '';
    int? id = prefs.getInt('user_id');
    // String utype = prefs.getString('user_type') ?? '';
    setState(() {
      fullname = "$firstName $lastName";
      userID = id;
      // userType = utype;
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No border radius
          ),
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(
                "No",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog first
                await _logout(); // Then log out
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(
                "Yes",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _navigateToPage(String page) {
    widget.onNavigate(page);
    widget.onToggle();

    // Handle redirection
    if (page == "Dashboard") {
      if (userID != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeniorDashboard(
              userId: userID!,
            ),
          ),
        );
      }
    } else if (page == "News") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewsPage()),
      );
    }
    // else if (page == "Announcements") {
    //   Navigator.push(context,
    //       MaterialPageRoute(builder: (_) => const AnnouncementsPage()));
    // }
    //else if (page == "Attendance") {
    //   Navigator.push(
    //       context, MaterialPageRoute(builder: (_) => const AttendancePage()));
    // } else if (page == "Manage Profile") {
    //   Navigator.push(context,
    //       MaterialPageRoute(builder: (_) => const ManageProfilePage()));
    // }
    else if (page == "Logout") {
      _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: widget.isCollapsed ? 70 : 250,
      duration: const Duration(milliseconds: 200),
      color: const Color(0xFF103c1d),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFF3ECB6C),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Image.asset(
                      'assets/logo/cc_white.png',
                      height: 30,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onToggle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!widget.isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      fullname.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          buildMenuItem(Icons.dashboard, "Dashboard"),
          if (!widget.isCollapsed) sectionTitle("PUBLICATION"),
          buildMenuItem(Icons.article, "News"),
          buildMenuItem(Icons.announcement, "Announcements"),
          buildMenuItem(Icons.app_registration, "Attendance"),
          if (!widget.isCollapsed) sectionTitle("ACTION"),
          buildMenuItem(Icons.settings, "Manage Profile"),
          buildMenuItem(Icons.logout, "Logout"),
        ],
      ),
    );
  }

  Widget buildMenuItem(IconData icon, String title) {
    return InkWell(
      onTap: () => _navigateToPage(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (!widget.isCollapsed) ...[
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

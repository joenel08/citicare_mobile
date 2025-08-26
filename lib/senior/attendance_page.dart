import 'dart:convert';
import 'package:citicare/global_url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sidebar_senior.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool isSidebarOpen = false;
  List assistances = []; // store assistance data

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userIdInt = prefs.getInt("user_id");
      String userId = userIdInt?.toString() ?? "";
      print(userId);
      // final int userId = 1; // Replace with logged-in user id
      Uri fetchAnnUri = buildUri('users/fetch_assistance_check_attendance.php');

      final response = await http.post(
        fetchAnnUri,
        body: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);

        if (res['status'] == 'success') {
          setState(() {
            assistances = res['data'];
          });
        } else {
          debugPrint("Error: ${res['message']}");
        }
      } else {
        debugPrint("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error fetching assistance: $e');
    }
  }

  void toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  color: const Color(0xFF3ECB6C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/logo/citicare_white.png', height: 28),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: toggleSidebar,
                      ),
                    ],
                  ),
                ),

                // Subheader
                Container(
                  width: double.infinity,
                  color: const Color(0xFF28A745),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Text(
                    "Attendance",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),

                // Assistance List
                // Assistance List
                Expanded(
                  child: assistances.isEmpty
                      ? const Center(
                          child: Text("No assistance records found."),
                        )
                      : RefreshIndicator(
                          color: Colors.green[700],
                          onRefresh:
                              _fetchAttendance, // ⬅️ this runs when user pulls down
                          child: ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(), // ⬅️ ensures pull works even if few items
                            padding: const EdgeInsets.all(12),
                            itemCount: assistances.length,
                            itemBuilder: (context, index) {
                              final item = assistances[index];
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['assistance_description'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text("Category: ${item['category']}"),
                                      Text("Date Given: ${item['date_given']}"),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Icon(
                                            item['attended'] == 1
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: item['attended'] == 1
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item['attended'] == 1
                                                ? "Attended"
                                                : "Not Attended",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: item['attended'] == 1
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Sidebar Backdrop
          if (isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: toggleSidebar,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

          // Sidebar
          if (isSidebarOpen)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: SafeArea(
                child: SeniorSidebar(
                  onNavigate: (_) {},
                  isCollapsed: false,
                  onToggle: toggleSidebar,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

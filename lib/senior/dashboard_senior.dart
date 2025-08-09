import 'dart:convert';

import 'package:citicare/global_url.dart';
import 'package:citicare/senior/QR_code_generator.dart';
import 'package:citicare/senior/id_card_generator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sidebar_senior.dart';
import 'package:http/http.dart' as http;

class SeniorDashboard extends StatefulWidget {
  final int userId;

  const SeniorDashboard({
    super.key,
    required this.userId,
  });

  @override
  State<SeniorDashboard> createState() => _SeniorDashboardState();
}

class _SeniorDashboardState extends State<SeniorDashboard> {
  String selectedPage = "Dashboard";
  bool isSidebarOpen = false;
  String fullname = "";
  Map<String, dynamic>? profile;
  @override
  void initState() {
    super.initState();
    _loadFullname();
    _fetchProfileData();
  }

  Future<void> _loadFullname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String firstName = prefs.getString('profile_first_name') ?? '';
    String lastName = prefs.getString('profile_last_name') ?? '';
    setState(() {
      fullname = "$firstName $lastName";
    });
  }

  Future<void> _fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');
    print(userId);

    try {
      // final response = await http.get(Uri.parse(
      //     'http://192.168.100.4:8080/citicare/users/get_senior_info_for_id.php?user_id=$userId'));

      Uri seniorInfoUri = buildUri('get_senior_info_for_id.php', {
        'user_id': userId,
      });

      final response = await http.get(seniorInfoUri);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['status'] == 'success') {
          // Get the raw path from database
          String qrPath = res['data']['qr_code'];

          // Remove any existing base URL if present
          qrPath = qrPath.replaceAll('http://192.168.100.4/citicare/', '');
          qrPath = qrPath.replaceAll('http://192.168.100.4/', '');
          qrPath = qrPath.replaceAll('/citicare/', '');

          setState(() {
            profile = res['data'];
            profile!['qr_code'] = 'http://192.168.100.4/citicare/$qrPath';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
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
          // MAIN CONTENT
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Green AppBar
                Container(
                  color: const Color(0xFF3ECB6C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/logo/citicare_white.png',
                        height: 28,
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: toggleSidebar,
                      ),
                    ],
                  ),
                ),

                // Subheader with page title
                Container(
                  width: double.infinity,
                  color: const Color(0xFF28A745),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    selectedPage,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),

                // Dashboard content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome ${fullname.isNotEmpty ? fullname.toUpperCase() : 'USER'}!",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "This system is designed to modernize and improve the efficiency of the registration process for vulnerable populations, including persons with disabilities (PWDs), senior citizens, and solo parents.",
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (profile != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => IDCardGeneratorPage(
                                          profile: profile!),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green, // Background color
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.zero, // No border radius
                                ),
                              ),
                              child: const Text(
                                "Preview & Download ID Card",
                                style: TextStyle(
                                    color:
                                        Colors.white), // Optional: white text
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (profile == null ||
                                    profile!['qr_code'] == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('QR code not available yet')),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QRCodePreviewPage(
                                        qrCodeUrl: profile!['qr_code']),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                  side: const BorderSide(
                                    color: Colors.green,
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "View & Download QR Code", // Updated text
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          // Backdrop
          if (isSidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: toggleSidebar,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

          // Modal Sidebar
          if (isSidebarOpen)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: SafeArea(
                child: SeniorSidebar(
                  onNavigate: (page) {
                    setState(() {
                      selectedPage = page;
                      isSidebarOpen = false;
                    });
                  },
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

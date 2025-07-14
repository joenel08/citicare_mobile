import 'package:flutter/material.dart';
import 'sidebar_senior.dart';

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
  String selectedPage = "Home";
  bool isSidebarOpen = false;

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
                        'assets/logo/citicare_white.png', // your logo path
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
                  color: const Color(0xFF28A745), // deeper green
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
                            const Text(
                              "Welcome User!",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "This system is designed to modernize and improve the efficiency of the registration process for vulnerable populations, including persons with disabilities (PWDs), senior citizens, and solo parents.",
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF28A745),
                              ),
                              child: const Text("Continue"),
                            )
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

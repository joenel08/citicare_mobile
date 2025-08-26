import 'dart:convert';
import 'package:citicare/global_url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sidebar_senior.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementsPage> {
  bool isSidebarOpen = false;
  List<dynamic> newsList = [];
  List<dynamic> filteredAnnList = [];

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  final List<String> months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      Uri fetchAnnUri = buildUri('users/fetch_announcements.php');

      final response = await http.get(fetchAnnUri);

      if (response.statusCode == 200) {
        final res = json.decode(response.body);

        if (res['status'] == 'success') {
          List<dynamic> allAnn = res['data'];
          allAnn.sort((a, b) => DateTime.parse(b['pub_date'])
              .compareTo(DateTime.parse(a['pub_date'])));

          setState(() {
            newsList = allAnn.take(5).toList(); // Limit to latest 5
            _filterAnn(); // Default filter
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
    }
  }

  void _filterAnn() {
    setState(() {
      filteredAnnList = newsList.where((news) {
        final pubDate = DateTime.tryParse(news['pub_date'] ?? '');
        return pubDate != null &&
            pubDate.month == selectedMonth &&
            pubDate.year == selectedYear;
      }).toList();
    });
  }

  void toggleSidebar() {
    setState(() {
      isSidebarOpen = !isSidebarOpen;
    });
  }

  void _showNewsModal(dynamic news) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7, // Set max height
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Date
                Text(
                  news['news_title'] ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  news['pub_date'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      news['content'] ?? '',
                      textAlign: TextAlign.justify, // Justify the text
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey, // Gray background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // No border radius
                      ),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                          color: Colors
                              .white), // Optional: white text for contrast
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
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
                    "Announcements",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),

                // Filter Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedMonth,
                          items: List.generate(
                            12,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text(months[index]),
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) selectedMonth = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedYear,
                          items: List.generate(
                            5,
                            (index) => DropdownMenuItem(
                              value: DateTime.now().year - index,
                              child: Text('${DateTime.now().year - index}'),
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) selectedYear = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _filterAnn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text(
                          "Filter",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchAnnouncements,
                    color: Colors.green[700], // spinner color
                    backgroundColor: Colors.white, // background behind spinner
                    child: filteredAnnList.isEmpty
                        ? ListView(
                            // ✅ must use ListView (not Center) so RefreshIndicator works
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text("No announcements available")),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredAnnList.length,
                            itemBuilder: (context, index) {
                              final news = filteredAnnList[index];
                              return buildNewsCard(news);
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

  Widget buildNewsCard(dynamic news) {
    String imageUrl = news['attachment'] ?? '';
    if (imageUrl.isNotEmpty) {
      // remove the base URL if it exists
      // imageUrl = imageUrl.replaceAll('http://192.168.100.4:8080/citicare/', '');

      // build a proper Uri
      Uri imageUri = buildUri(imageUrl);

      // if you need a String for Image.network etc.
      imageUrl = imageUri.toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 180,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(news['pub_date'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(news['announcement_title'] ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(news['content'] ?? '',
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _showNewsModal(news),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text("View"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

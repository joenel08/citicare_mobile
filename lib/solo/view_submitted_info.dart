import 'package:citicare/global_url.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ViewSubmittedInfoPage extends StatefulWidget {
  const ViewSubmittedInfoPage({super.key});

  @override
  State<ViewSubmittedInfoPage> createState() => _ViewSubmittedInfoPageState();
}

class _ViewSubmittedInfoPageState extends State<ViewSubmittedInfoPage> {
  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSubmittedData();
  }

  Future<void> fetchSubmittedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userIdInt = prefs.getInt("user_id");
    String userId = userIdInt?.toString() ?? "";

    // Uri seniorInfoUri = buildUri('users/get_senior_info.php?user_id=$userId');

    // final res = await http.get(seniorInfoUri);

    // final uri = Uri.parse(
    //     "http://192.168.100.4:8080/citicare/users/get_senior_info.php?user_id=$userId");

    // final res = await http.get(uri);

    Uri seniorInfoUri = buildUri('users/get_solo_info.php');

    final res = await http.post(
      seniorInfoUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"user_id": userId}),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      if (json['success']) {
        setState(() {
          data = json['data'];
          loading = false;
        });
      } else {
        setState(() => loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(json['message'] ?? "Failed")));
        }
      }
    } else {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${res.statusCode}")));
      }
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Image.asset(
          'assets/logo/citicare_white.png',
          height: 28,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text("No data found."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "${data!['first_name']} ${data!['middle_name']} ${data!['last_name']}"
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.green, width: 2),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoItem("Date of Birth", data!['birthdate']),
                            _infoItem("Age", data!['age'].toString()),
                            _infoItem("Gender", data!['gender']),
                            _infoItem("Civil Status", data!['civil_status']),
                            _infoItem("Education", data!['education']),
                            _infoItem("Occupation", data!['occupation']),
                            _infoItem(
                                "Place of Birth", data!['place_of_birth']),
                            _infoItem("Contact No", data!['contact_no']),
                            _infoItem("Barangay", data!['barangay']),
                            _infoItem("Municipality", data!['municipality']),
                            _infoItem("Province", data!['province']),
                            _infoItem(
                              "Emergency Contact",
                              "${data!['emergency_name']} (${data!['emergency_relationship']}) - ${data!['emergency_contact']}",
                            ),
                            _infoItem(
                                "Pensioner",
                                data!['social_pensioner'] == "1"
                                    ? "Yes"
                                    : "No"),
                            _infoItem("Retiree",
                                data!['retiree'] == "1" ? "Yes" : "No"),
                            _infoItem(
                                "Retiree Details", data!['retiree_desc'] ?? ''),
                            _infoItem("GSIS/SSS/Vet. Pensioner",
                                data!['is_gsis'] == "1" ? "Yes" : "No"),
                            _infoItem("Health Status", data!['health_status']),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

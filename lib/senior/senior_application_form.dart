import 'dart:convert';
import 'dart:io';
import 'package:citicare/senior/view_submitted_info.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citicare/global_url.dart';

class SeniorApplicationForm extends StatefulWidget {
  const SeniorApplicationForm({super.key});

  @override
  State<SeniorApplicationForm> createState() => _SeniorApplicationFormState();
}

class _SeniorApplicationFormState extends State<SeniorApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // First Section
  final TextEditingController fname = TextEditingController();
  final TextEditingController mname = TextEditingController();
  final TextEditingController lname = TextEditingController();
  DateTime? birthDate;
  String? gender;
  String? civilStatus;
  int age = 0;

  // Second Section
  String? education;
  final TextEditingController occupation = TextEditingController();
  final TextEditingController pob = TextEditingController();
  final TextEditingController contactNo = TextEditingController();
  String barangay = "Bangad";

  // Third Section
  final TextEditingController emergencyName = TextEditingController();
  final TextEditingController emergencyContact = TextEditingController();
  final TextEditingController emergencyRelation = TextEditingController();

  // Fourth Section
  bool isPensioner = false;
  bool isRetiree = false;
  bool isGSIS = false;
  final TextEditingController retireeDetails = TextEditingController();
  String? healthStatus;

  // Uploads
  File? birthProof;
  File? residencyProof;
  File? photoId;

  Future<void> pickImage(ImageSource source, Function(File) onSelected) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      onSelected(File(picked.path));
    }
  }

  void calculateAge(DateTime? date) {
    if (date != null) {
      final now = DateTime.now();
      final diff = now.difference(date).inDays ~/ 365;
      setState(() {
        age = diff;
      });
    }
  }

  void nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 4) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void previousStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  Future<void> uploadFormData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userIdInt = prefs.getInt("user_id");
      String userId = userIdInt?.toString() ?? "";

      final uri = buildUri("users/save_senior_form.php");
      debugPrint("Sending request to: $uri");

      var request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = userId
        ..fields['municipality'] = "Santa Maria"
        ..fields['province'] = "Isabela"
        ..fields['first_name'] = fname.text
        ..fields['middle_name'] = mname.text
        ..fields['last_name'] = lname.text
        ..fields['birthdate'] = birthDate?.toIso8601String() ?? ""
        ..fields['age'] = age.toString()
        ..fields['gender'] = gender ?? ''
        ..fields['civil_status'] = civilStatus ?? ''
        ..fields['education'] = education ?? ''
        ..fields['occupation'] = occupation.text
        ..fields['place_of_birth'] = pob.text
        ..fields['contact_no'] = contactNo.text
        ..fields['barangay'] = barangay
        ..fields['emergency_name'] = emergencyName.text
        ..fields['emergency_contact'] = emergencyContact.text
        ..fields['emergency_relationship'] = emergencyRelation.text
        ..fields['social_pensioner'] = isPensioner ? "1" : "0"
        ..fields['retiree'] = isRetiree ? "1" : "0"
        ..fields['retiree_desc'] = isRetiree ? retireeDetails.text : ""
        ..fields['is_gsis'] = isGSIS ? "1" : "0"
        ..fields['health_status'] = healthStatus ?? '';

      // Attach files if they exist
      if (birthProof != null) {
        request.files.add(
            await http.MultipartFile.fromPath('birth_proof', birthProof!.path));
      }
      if (residencyProof != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'residency_proof', residencyProof!.path));
      }
      if (photoId != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo_id', photoId!.path));
      }

      // Send request
      final response = await request.send();

      // Read server response body
      final responseBody = await response.stream.bytesToString();
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Server Response: $responseBody");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        String appNo = data["application_no"];
        int scId = data["sc_id"];
        int userIdReturned = data["user_id"].toString() as int;

        debugPrint("Application No: $appNo");
        debugPrint("Inserted Senior ID: $scId");
        debugPrint("User ID: $userIdReturned");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Form submitted successfully.\n$responseBody"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ViewSubmittedInfoPage(
                      userId: userIdReturned,
                    )),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Failed to submit form. [${response.statusCode}] $responseBody"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stack) {
      debugPrint("Upload failed: $e");
      debugPrint("Stacktrace: $stack");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildFirstSection(),
      _buildSecondSection(),
      _buildThirdSection(),
      _buildFourthSection(),
      _buildUploadSection(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      appBar: AppBar(
        title: const Text("Senior Citizen Application"),
        backgroundColor: Colors.green[700],
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.green.shade700,
                        width: 2,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: steps[_currentStep],
                ),
              ),
            ),
          ),

          // ✅ Loading overlay on top of form
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed:
                    _isLoading ? null : previousStep, // disable while loading
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.green),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                _currentStep == 4 ? "Submit" : "Next",
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        if (_currentStep == 4) {
                          // Show confirmation dialog
                          bool confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Submission"),
                              content: const Text(
                                  "Are you sure you want to submit this application?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.green),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ),
                                  child: const Text(
                                    "Submit Application",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setState(() => _isLoading = true);
                            await uploadFormData();
                            setState(() => _isLoading = false);
                          }
                        } else {
                          nextStep();
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _styledInput(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      labelStyle: const TextStyle(color: Colors.black87),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.green, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildFirstSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Basic Info",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // First Name
        TextFormField(
          controller: fname,
          decoration: _styledInput("First Name"),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        // Middle Name
        TextFormField(
          controller: mname,
          decoration: _styledInput("Middle Name"),
        ),
        const SizedBox(height: 12),

        // Last Name
        TextFormField(
          controller: lname,
          decoration: _styledInput("Last Name"),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        // Date of Birth
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
            text: birthDate != null
                ? DateFormat('MM-dd-yyyy').format(birthDate!)
                : '',
          ),
          decoration: _styledInput("Date of Birth").copyWith(
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: birthDate ?? DateTime(1960),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                birthDate = picked;
                calculateAge(picked);
              });
            }
          },
        ),
        const SizedBox(height: 8),
        Text("Age: $age"),

        const SizedBox(height: 16),

        // Gender Dropdown
        DropdownButtonFormField<String>(
          value: gender,
          decoration: _styledInput("Gender"),
          items: ["Male", "Female"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => gender = val),
          validator: (val) => val == null ? "Required" : null,
        ),
        const SizedBox(height: 12),

        // Civil Status Dropdown
        DropdownButtonFormField<String>(
          value: civilStatus,
          decoration: _styledInput("Civil Status"),
          items: ["Single", "Married", "Widowed", "Separated"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => civilStatus = val),
        ),
      ],
    );
  }

  Widget _buildSecondSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Other Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: education,
          decoration: _styledInput("Educational Attainment"),
          items: ["Elementary", "High School", "College", "Post-Graduate"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => education = val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: occupation,
          decoration: _styledInput("Occupation"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: pob,
          decoration: _styledInput("Place of Birth"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: contactNo,
          decoration: _styledInput("Contact Number"),
        ),
        const SizedBox(height: 12),
        const Text("Complete Address (Barangay Only)",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: barangay,
          decoration: _styledInput("Barangay"),
          items: [
            "Bangad",
            "Buenavista",
            "Calamagui North",
            "Calamagui East",
            "Calamagui West",
            "Divisoria",
            "Lingaling",
            "Mozzozzin Sur",
            "Mozzozzin North",
            "Naganacan",
            "Poblacion 1",
            "Poblacion 2",
            "Poblacion 3",
            "Quinagabian",
            "San Antonio",
            "San Isidro East",
            "San Isidro West",
            "San Rafael West",
            "San Rafael East",
            "Villabuena"
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => barangay = val!),
        ),
        const SizedBox(height: 8),
        const Text("Municipality: Santa Maria"),
        const Text("Province: Isabela"),
      ],
    );
  }

  Widget _buildThirdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("In Case of Emergency",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: emergencyName,
          decoration: _styledInput("Name"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emergencyContact,
          decoration: _styledInput("Contact No."),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emergencyRelation,
          decoration: _styledInput("Relationship"),
        ),
      ],
    );
  }

  Widget _buildFourthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Status & Health",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text("Senior Citizen is Social Pensioner"),
          value: isPensioner,
          onChanged: (val) => setState(() => isPensioner = val!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: Row(
            children: [
              const Expanded(child: Text("Senior is a retiree (specify):")),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: retireeDetails,
                  decoration: _styledInput("Details"),
                ),
              ),
            ],
          ),
          value: isRetiree,
          onChanged: (val) => setState(() => isRetiree = val!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text("Senior is a GSIS/SSS/Vet. Pensioner"),
          value: isGSIS,
          onChanged: (val) => setState(() => isGSIS = val!),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 10),
        const Text("Health Status",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Column(
          children: ["Physically Fit", "Sickly/Frail", "Bedridden", "PWD"]
              .map((status) {
            return RadioListTile(
              title: Text(status),
              value: status,
              groupValue: healthStatus,
              onChanged: (val) => setState(() => healthStatus = val.toString()),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Requirements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _imagePicker("Birth/Marriage/Baptismal Certificate", birthProof,
            (file) => setState(() => birthProof = file)),
        _imagePicker("Proof of Residency", residencyProof,
            (file) => setState(() => residencyProof = file)),
        _imagePicker("1x1 Photo (White Background)", photoId,
            (file) => setState(() => photoId = file)),
      ],
    );
  }

  Widget _imagePicker(String label, File? file, Function(File) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            if (file != null)
              Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => pickImage(ImageSource.gallery, onPicked),
              icon: const Icon(Icons.upload, color: Colors.green),
              label: const Text("Choose File",
                  style: TextStyle(color: Colors.green)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // removes radius
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

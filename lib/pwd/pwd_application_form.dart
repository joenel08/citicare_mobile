import 'dart:convert';
import 'dart:io';
import 'package:citicare/pwd/view_submitted_info.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citicare/global_url.dart';

class PwdApplicationForm extends StatefulWidget {
  const PwdApplicationForm({super.key});

  @override
  State<PwdApplicationForm> createState() => _PwdApplicationFormState();
}

class _PwdApplicationFormState extends State<PwdApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // First Section
  final TextEditingController fname = TextEditingController();
  final TextEditingController mname = TextEditingController();
  final TextEditingController lname = TextEditingController();
  final TextEditingController suffix = TextEditingController();

  DateTime? birthDate;
  String? gender;
  String? civilStatus;
  int age = 0;

//pwd section
// Selected disabilities (multi-select)
  List<String> selectedDisabilities = [];

  // Selected cause(s)
  bool isCongenital = false;
  bool isAcquired = false;

  // Subcategories for congenital and acquired
  List<String> congenitalOptions = [
    "Autism",
    "ADHD",
    "Cerebral Palsy",
    "Down Syndrome",
  ];

  List<String> acquiredOptions = [
    "Chronic Illness",
    "Cerebral Palsy",
    "Injury",
  ];

  // Track selected sub-causes
  List<String> selectedCongenital = [];
  List<String> selectedAcquired = [];
  // Second Section
  String? education;
  // final TextEditingController occupation = TextEditingController();
  String? selectedOccupation;
  TextEditingController otherOccupationController = TextEditingController();
  final TextEditingController pob = TextEditingController();
  // final TextEditingController contactNo = TextEditingController();
  String barangay = "Bangad";

//organization information

  final TextEditingController organizationAffiliated = TextEditingController();
  final TextEditingController oaContactPerson = TextEditingController();
  final TextEditingController officeAddress = TextEditingController();
  final TextEditingController oacontactInfo = TextEditingController();

  final TextEditingController sssNo = TextEditingController();
  final TextEditingController gsisNo = TextEditingController();
  final TextEditingController pagibigNo = TextEditingController();
  final TextEditingController psnNo = TextEditingController();
  final TextEditingController philhealthNo = TextEditingController();

  // Third Section
  String? employmentStatus;
  String? employmentType;
  String? employmentCategory;

  // Fourth Section

  final TextEditingController fatherLastname = TextEditingController();
  final TextEditingController fatherFirstname = TextEditingController();
  final TextEditingController fatherMiddlename = TextEditingController();

  final TextEditingController motherLastname = TextEditingController();
  final TextEditingController motherFirstname = TextEditingController();
  final TextEditingController motherMiddlename = TextEditingController();

  final TextEditingController guardianLastname = TextEditingController();
  final TextEditingController guardianFirstname = TextEditingController();
  final TextEditingController guardianMiddlename = TextEditingController();

  // Uploads
  File? birthProof;
  File? medicalCertificate;
  File? indigencyCert;
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
      if (_currentStep < 6) {
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

      print(userId);

      // Validate birthdate before sending
      String birthdateString = "";
      if (birthDate != null) {
        birthdateString = DateFormat('yyyy-MM-dd').format(birthDate!);
        debugPrint("Formatted birthdate: $birthdateString");
      } else {
        debugPrint("Warning: Birthdate is null");
        // Handle null birthdate appropriately - maybe show error to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Please select a birthdate"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return; // Don't proceed without birthdate
      }

      final uri = buildUri("users/save_pwd_form.php");
      debugPrint("Sending request to: $uri");

      var request = http.MultipartRequest('POST', uri)
        ..fields['user_id'] = userId
        ..fields['applicationType'] = "New"
        ..fields['first_name'] = fname.text
        ..fields['middle_name'] = mname.text
        ..fields['last_name'] = lname.text
        ..fields['suffix'] = suffix.text
        ..fields['birthdate'] = birthdateString // Use the validated variable
        ..fields['age'] = age.toString()
        ..fields['age'] = age.toString()
        ..fields['gender'] = gender ?? ''
        ..fields['civil_status'] = civilStatus ?? ''
        ..fields['place_of_birth'] = pob.text
        ..fields['barangay'] = barangay
        ..fields['education'] = education ?? ''
        ..fields['occupation'] = selectedOccupation == "Others"
            ? otherOccupationController.text
            : selectedOccupation ?? ''
        ..fields['status_of_employment'] = employmentStatus ?? ''
        ..fields['type_of_employment'] = employmentType ?? ''
        ..fields['category_of_employment'] = employmentCategory ?? ''
        ..fields['organization_affiliation'] = organizationAffiliated.text
        ..fields['contact_person'] = oaContactPerson.text
        ..fields['office_address'] = officeAddress.text
        ..fields['contact_information'] = oacontactInfo.text
        ..fields['sss_no'] = sssNo.text
        ..fields['gsis_no'] = gsisNo.text
        ..fields['pagibig_no'] = pagibigNo.text
        ..fields['psn_no'] = psnNo.text
        ..fields['philhealth_no'] = philhealthNo.text
        ..fields['father_lastname'] = fatherLastname.text
        ..fields['father_firstname'] = fatherFirstname.text
        ..fields['father_middlename'] = fatherMiddlename.text
        ..fields['mother_lastname'] = motherLastname.text
        ..fields['mother_firstname'] = motherFirstname.text
        ..fields['mother_middlename'] = motherMiddlename.text
        ..fields['guardian_lastname'] = guardianLastname.text
        ..fields['guardian_firstname'] = guardianFirstname.text
        ..fields['guardian_middlename'] = guardianMiddlename.text
        ..fields['type_of_disability'] = selectedDisabilities.join(",")
        ..fields['cause_of_disability'] = [
          if (isCongenital) "Congenital",
          if (isAcquired) "Acquired",
        ].join(",")
        ..fields['cause_of_disability_type'] = [
          ...selectedCongenital,
          ...selectedAcquired,
        ].join(",");

      // Attach files if they exist
      if (birthProof != null) {
        request.files.add(
            await http.MultipartFile.fromPath('birth_proof', birthProof!.path));
      }
      if (indigencyCert != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'indegency_certificate', indigencyCert!.path));
      }
      if (medicalCertificate != null) {
        request.files.add(await http.MultipartFile.fromPath(
            'medical_certificate', medicalCertificate!.path));
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

        // // int userIdReturned = data["user_id"].toString() as int;
        // int userIdReturned = int.parse(data["user_id"].toString());

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
                      userId: int.tryParse(userId) ?? 0,
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
      _buildPWDInfoSection(),
      _buildSecondSection(),
      _buildOrganizationInfo(),
      _buildFourthSection(),
      _buildUploadSection(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      appBar: AppBar(
        title: const Text("PWD Application Form"),
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
                _currentStep == 5 ? "Submit" : "Next",
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        if (_currentStep == 5) {
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
        TextFormField(
          controller: suffix,
          decoration: _styledInput("Suffix"),
          // validator: (val) => val!.isEmpty ? "Required" : null,
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

  Widget _buildPWDInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Disability Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // --- Type of Disability checkboxes ---
        const Text("Type of Disability",
            style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          children: [
            "Deaf or Hard of Hearing",
            "Intellectual Disability",
            "Learning Disability",
            "Mental Disability",
            "Physical Disability (Orthopedic)",
            "Psychosocial Disability",
            "Speech and Language Impairment",
            "Visual Disability",
            "Cancer (RA12215)",
            "Rare Disease (RA10747)",
          ].map((e) {
            return CheckboxListTile(
              title: Text(e),
              value: selectedDisabilities.contains(e),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    selectedDisabilities.add(e);
                  } else {
                    selectedDisabilities.remove(e);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // --- Cause of Disability checkboxes ---
        const Text("Cause of Disability",
            style: TextStyle(fontWeight: FontWeight.bold)),
        CheckboxListTile(
          title: const Text("Congenital / Inborn"),
          value: isCongenital,
          onChanged: (val) {
            setState(() {
              isCongenital = val ?? false;
              if (!isCongenital) selectedCongenital.clear();
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (isCongenital)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: congenitalOptions.map((e) {
                return CheckboxListTile(
                  title: Text(e),
                  value: selectedCongenital.contains(e),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedCongenital.add(e);
                      } else {
                        selectedCongenital.remove(e);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),

        CheckboxListTile(
          title: const Text("Acquired"),
          value: isAcquired,
          onChanged: (val) {
            setState(() {
              isAcquired = val ?? false;
              if (!isAcquired) selectedAcquired.clear();
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (isAcquired)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: acquiredOptions.map((e) {
                return CheckboxListTile(
                  title: Text(e),
                  value: selectedAcquired.contains(e),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedAcquired.add(e);
                      } else {
                        selectedAcquired.remove(e);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
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
        DropdownButtonFormField<String>(
          value: selectedOccupation,
          decoration: _styledInput("Occupation"),
          items: [
            "Managers",
            "Professionals",
            "Technicians and Associate Professionals",
            "Clerical Support Workers",
            "Service and Sales workers",
            "Skilled Agricultural, Forestry and Fishery Workers",
            "Craft and Related Trade Workers",
            "Others"
          ].map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              selectedOccupation = val;
              if (val != "Others") {
                otherOccupationController.clear();
              }
            });
          },
        ),
        if (selectedOccupation == "Others") ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: otherOccupationController,
            decoration: _styledInput("Please specify Occupation"),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: employmentStatus,
          decoration: _styledInput("Status of employment"),
          items: ["Employed", "Unemployed", "Self-employed"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => employmentStatus = val),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: employmentType,
          decoration: _styledInput("Types of employment"),
          items: ["Permanent/Regular", "Seasonal", "Casual", "Emergency"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => employmentType = val),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: employmentCategory,
          decoration: _styledInput("Category of employment"),
          items: ["Government", "Private"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => employmentCategory = val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: pob,
          decoration: _styledInput("Place of Birth"),
        ),
        const SizedBox(height: 12),
        // TextFormField(
        //   controller: contactNo,
        //   decoration: _styledInput("Contact Number"),
        // ),
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

  Widget _buildOrganizationInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Organization Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextFormField(
        controller: organizationAffiliated,
        decoration: _styledInput("Organization Affiliated"),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: oaContactPerson,
        decoration: _styledInput("Contact Person"),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: officeAddress,
        decoration: _styledInput("Office Address"),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: oacontactInfo,
        decoration: _styledInput("Contact Information"),
      ),
      const SizedBox(height: 20),
      const Text("ID Reference Number",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextFormField(
        controller: sssNo,
        decoration: _styledInput("SSS No."),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: gsisNo,
        decoration: _styledInput("GSIS No."),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: pagibigNo,
        decoration: _styledInput("PAGIBIG No."),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: psnNo,
        decoration: _styledInput("PSN No."),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: philhealthNo,
        decoration: _styledInput("Philhealth No."),
      ),
    ]);
  }

  Widget _buildFourthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Family Background",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text("Father's Name",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: fatherLastname,
          decoration: _styledInput("Lastname"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fatherFirstname,
          decoration: _styledInput("Firstname"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: fatherMiddlename,
          decoration: _styledInput("Middlename"),
        ),
        const SizedBox(height: 16),
        const Text("Mother's Name",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: motherLastname,
          decoration: _styledInput("Lastname"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: motherFirstname,
          decoration: _styledInput("Firstname"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: motherMiddlename,
          decoration: _styledInput("Middlename"),
        ),
        const SizedBox(height: 16),
        const Text("Guardian's Name",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: guardianLastname,
          decoration: _styledInput("Lastname"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: guardianFirstname,
          decoration: _styledInput("Firstname"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: guardianMiddlename,
          decoration: _styledInput("Middlename"),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Upload Requirements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _imagePicker("Birth Certificate", birthProof,
            (file) => setState(() => birthProof = file)),
        _imagePicker("Medical Certificate", medicalCertificate,
            (file) => setState(() => medicalCertificate = file)),
        _imagePicker("Indigency", indigencyCert,
            (file) => setState(() => indigencyCert = file)),
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

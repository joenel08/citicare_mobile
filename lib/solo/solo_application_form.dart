import 'dart:convert';

import 'package:citicare/solo/view_submitted_info.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SoloApplicationForm extends StatefulWidget {
  const SoloApplicationForm({super.key});

  @override
  State<SoloApplicationForm> createState() => _SoloApplicationFormState();
}

class _SoloApplicationFormState extends State<SoloApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  int age = 0;

  // Basic Info
  TextEditingController fname = TextEditingController();
  TextEditingController mname = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController extensionName = TextEditingController();
  DateTime? birthDate;
  String? gender;
  String? civilStatus;
  String? education;
  TextEditingController religion = TextEditingController();
  TextEditingController monthlyIncome = TextEditingController();
  TextEditingController email = TextEditingController();
  bool isPantawidBeneficiary = false;

  // Address
  String? barangay;
  final municipality = "Santa Maria";
  final province = "Isabela";

  // Family Composition
  List<Map<String, dynamic>> children = [];
  TextEditingController childName = TextEditingController();
  TextEditingController childAge = TextEditingController();
  TextEditingController childRelationship = TextEditingController();
  bool childWithDisability = false;
  TextEditingController childEducation = TextEditingController();
  TextEditingController childOccupation = TextEditingController();

  // Solo Parent Classification
  String? soloParentType;
  TextEditingController soloParentSince = TextEditingController();
  TextEditingController otherClassification = TextEditingController();

  // Needs/Problems
  TextEditingController needsProblems = TextEditingController();

  // Family Resources
  TextEditingController familyResources = TextEditingController();

  // Certification
  bool certifyInformation = false;

  // Documents
  File? birthProof;
  File? residencyProof;
  File? incomeProof;
  File? affidavit;
  File? otherDocuments;
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
      if (_currentStep < 5) {
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

  void addChild() {
    if (childName.text.isNotEmpty && childAge.text.isNotEmpty) {
      setState(() {
        children.add({
          'name': childName.text,
          'age': childAge.text,
          'relationship': childRelationship.text,
          'disability': childWithDisability,
          'education': childEducation.text,
          'occupation': childOccupation.text,
        });
        childName.clear();
        childAge.clear();
        childRelationship.clear();
        childEducation.clear();
        childOccupation.clear();
        childWithDisability = false;
      });
    }
  }

  void removeChild(int index) {
    setState(() {
      children.removeAt(index);
    });
  }

  Future<void> uploadFormData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userIdInt = prefs.getInt("user_id");
    String userId = userIdInt?.toString() ?? "";

    final uri =
        Uri.parse("http://192.168.100.4/citicare/users/save_solo_form.php");

    var request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId
      ..fields['first_name'] = fname.text
      ..fields['middle_name'] = mname.text
      ..fields['last_name'] = lname.text
      ..fields['extension_name'] = extensionName.text
      ..fields['birthdate'] = birthDate.toString()
      ..fields['age'] = age.toString()
      ..fields['gender'] = gender ?? ''
      ..fields['civil_status'] = civilStatus ?? ''
      ..fields['education'] = education ?? ''
      ..fields['religion'] = religion.text
      ..fields['monthly_income'] = monthlyIncome.text
      ..fields['email'] = email.text
      ..fields['pantawid_beneficiary'] = isPantawidBeneficiary ? "1" : "0"
      ..fields['barangay'] = barangay ?? ''
      ..fields['municipality'] = municipality
      ..fields['province'] = province
      ..fields['solo_parent_type'] = soloParentType ?? ''
      ..fields['solo_parent_since'] = soloParentSince.text
      ..fields['other_classification'] = otherClassification.text
      ..fields['needs_problems'] = needsProblems.text
      ..fields['family_resources'] = familyResources.text
      ..fields['certify_information'] = certifyInformation ? "1" : "0"
      ..fields['children'] = jsonEncode(children);

    if (birthProof != null) {
      request.files.add(
          await http.MultipartFile.fromPath('birth_proof', birthProof!.path));
    }
    if (residencyProof != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'residency_proof', residencyProof!.path));
    }
    if (incomeProof != null) {
      request.files.add(
          await http.MultipartFile.fromPath('income_proof', incomeProof!.path));
    }
    if (affidavit != null) {
      request.files
          .add(await http.MultipartFile.fromPath('affidavit', affidavit!.path));
    }
    if (otherDocuments != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'other_documents', otherDocuments!.path));
    }
    if (photoId != null) {
      request.files
          .add(await http.MultipartFile.fromPath('photo_id', photoId!.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseBody);
      if (jsonResponse['status'] == 'success') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Form submitted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ViewSubmittedInfoPage()),
          );
        }
      } else {
        throw Exception(jsonResponse['message'] ?? "Submission failed");
      }
    } else {
      throw Exception(
          "Server responded with status code: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildBasicInfoSection(),
      _buildAddressSection(),
      _buildFamilyCompositionSection(),
      _buildClassificationSection(),
      _buildNeedsAndResourcesSection(),
      _buildUploadSection(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEF),
      appBar: AppBar(
        title: const Text("Solo Parent Application"),
        backgroundColor: Colors.green[700],
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
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
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: steps[_currentStep],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: previousStep,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                _currentStep == 5 ? "Submit" : "Next",
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (_currentStep == 5) {
                    await uploadFormData();
                  } else {
                    nextStep();
                  }
                }
              },
            ),
          ])),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "I. Identifying Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Name Fields
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: fname,
                decoration: _styledInput("First Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: mname,
                decoration: _styledInput("Middle Name"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: lname,
                decoration: _styledInput("Last Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: extensionName,
                decoration: _styledInput("Extension Name (if any)"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Birth Date
        // Update your date picker code to this:
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                birthDate = date;
                age = DateTime.now().difference(date).inDays ~/
                    365; // Direct calculation
              });
            }
          },
          child: InputDecorator(
            decoration: _styledInput("Date of Birth"),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  birthDate != null
                      ? DateFormat('yyyy-MM-dd').format(birthDate!)
                      : 'Select date',
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Age (auto-computed)
        TextFormField(
          initialValue: age.toString(),
          decoration: _styledInput("Age"),
          readOnly: true,
        ),
        const SizedBox(height: 10),

        // Gender
        DropdownButtonFormField<String>(
          decoration: _styledInput("Sex"),
          value: gender,
          items: ['Male', 'Female'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              gender = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select gender';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Civil Status
        DropdownButtonFormField<String>(
          decoration: _styledInput("Civil Status"),
          value: civilStatus,
          items:
              ['Single', 'Married', 'Widowed', 'Separated'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              civilStatus = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select civil status';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Education
        DropdownButtonFormField<String>(
          decoration: _styledInput("Highest Educational Attainment"),
          value: education,
          items: ['Elementary', 'High School', 'College', 'Post Graduate']
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              education = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select education';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Religion
        TextFormField(
          controller: religion,
          decoration: _styledInput("Religion"),
        ),
        const SizedBox(height: 10),

        // Monthly Income
        TextFormField(
          controller: monthlyIncome,
          decoration: _styledInput("Monthly Income"),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),

        // Email
        TextFormField(
          controller: email,
          decoration: _styledInput("Email Address"),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Pantawid Beneficiary
        Row(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: Colors.grey, // Color when unchecked
              ),
              child: Checkbox(
                value: isPantawidBeneficiary,
                onChanged: (value) {
                  setState(() {
                    isPantawidBeneficiary = value ?? false;
                  });
                },
                activeColor: Colors.green[700], // Darker green when checked
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  isPantawidBeneficiary = !isPantawidBeneficiary;
                });
              },
              child: Text(
                "Pantawid Beneficiary?",
                style: TextStyle(
                  color: isPantawidBeneficiary
                      ? Colors.green[700]
                      : Colors.black87,
                  fontWeight: isPantawidBeneficiary
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    // List of barangays in Santa Maria, Isabela
    final barangays = [
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
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Complete Address",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Barangay
        DropdownButtonFormField<String>(
          decoration: _styledInput("Barangay"),
          value: barangay,
          items: barangays.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              barangay = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select barangay';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        // Municipality (fixed)
        TextFormField(
          initialValue: municipality,
          decoration: _styledInput("Municipality"),
          readOnly: true,
        ),
        const SizedBox(height: 10),

        // Province (fixed)
        TextFormField(
          initialValue: province,
          decoration: _styledInput("Province"),
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildFamilyCompositionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Family Composition (Children Only)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Child Form
        TextFormField(
          controller: childName,
          decoration: _styledInput("Child's Name"),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: childAge,
                decoration: _styledInput("Age"),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: childRelationship,
                decoration: _styledInput("Relationship"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: childEducation,
                decoration: _styledInput("Educational Attainment"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: childOccupation,
                decoration: _styledInput("Occupation"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: Colors.grey, // Color when unchecked
              ),
              child: Checkbox(
                value: childWithDisability,
                onChanged: (value) {
                  setState(() {
                    childWithDisability = value ?? false;
                  });
                },
                activeColor: Colors.green[700], // Darker green when checked
                checkColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  childWithDisability = !childWithDisability;
                });
              },
              child: Text(
                "With Disability?",
                style: TextStyle(
                  color:
                      childWithDisability ? Colors.green[700] : Colors.black87,
                  fontWeight:
                      childWithDisability ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: addChild,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.green, // Text color
            side: const BorderSide(color: Colors.green, width: 2), // Border
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // No radius
            ),
          ),
          child: const Text("Add Child"),
        ),
        const SizedBox(height: 20),

        // List of Children
        if (children.isNotEmpty)
          const Text(
            "Children Added:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ...children.asMap().entries.map((entry) {
          int idx = entry.key;
          var child = entry.value;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${child['name']}"),
                        Text("Age: ${child['age']}"),
                        Text("Relationship: ${child['relationship']}"),
                        Text("Education: ${child['education']}"),
                        Text("Occupation: ${child['occupation']}"),
                        Text(
                            "Disability: ${child['disability'] ? 'Yes' : 'No'}"),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => removeChild(idx),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildClassificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "II. Classification/Circumstances of being a Solo Parent",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Solo Parent Type
        Column(
          children: [
            RadioListTile<String>(
              title: const Text("Unwed/Unmarried"),
              value: "Unwed/Unmarried",
              groupValue: soloParentType,
              onChanged: (value) {
                setState(() {
                  soloParentType = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text("Separated/Annulled"),
              value: "Separated/Annulled",
              groupValue: soloParentType,
              onChanged: (value) {
                setState(() {
                  soloParentType = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text("Widow/er"),
              value: "Widow/er",
              groupValue: soloParentType,
              onChanged: (value) {
                setState(() {
                  soloParentType = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text("Others"),
              value: "Others",
              groupValue: soloParentType,
              onChanged: (value) {
                setState(() {
                  soloParentType = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (soloParentType != null)
          TextFormField(
            controller: soloParentSince,
            decoration: _styledInput("Since (Year)"),
            keyboardType: TextInputType.number,
          ),
        const SizedBox(height: 10),

        if (soloParentType == "Others")
          TextFormField(
            controller: otherClassification,
            decoration: _styledInput("Please specify"),
          ),
      ],
    );
  }

  Widget _buildNeedsAndResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "III. Needs/Problems of Solo Parent",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: needsProblems,
          decoration: _styledInput("Describe your needs/problems"),
          maxLines: 5,
        ),
        const SizedBox(height: 20),

        const Text(
          "IV. Family Resources",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: familyResources,
          decoration: _styledInput("Describe your family resources"),
          maxLines: 5,
        ),
        const SizedBox(height: 20),

        // Certification
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: certifyInformation,
              onChanged: (value) {
                setState(() {
                  certifyInformation = value ?? false;
                });
              },
              activeColor: Colors.green, // Green when checked
              checkColor: Colors.white, // White checkmark
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 12), // Better vertical alignment
                child: Text(
                  "I hereby certify that the information given above are true and correct",
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        certifyInformation ? Colors.green[700] : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!certifyInformation && _currentStep == 4)
          const Text(
            "You must certify the information to proceed",
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Required Documents",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          "Please upload the following documents:",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        const Text(
            "- Proof of solo parent status (death certificate, court order, affidavit, etc.)"),
        const Text("- Birth certificate(s) of your child/children"),
        const Text("- Proof of residency (barangay certificate)"),
        const Text("- Proof of income (ITR, certificate of employment, etc.)"),
        const Text("- Affidavit of being a solo parent"),
        const Text("- Other supporting documents"),
        const SizedBox(height: 20),

        // Document Uploads
        _buildDocumentUpload("Birth Proof", birthProof, (file) {
          setState(() {
            birthProof = file;
          });
        }),
        const SizedBox(height: 10),

        _buildDocumentUpload("Residency Proof", residencyProof, (file) {
          setState(() {
            residencyProof = file;
          });
        }),
        const SizedBox(height: 10),

        _buildDocumentUpload("Income Proof", incomeProof, (file) {
          setState(() {
            incomeProof = file;
          });
        }),
        const SizedBox(height: 10),

        _buildDocumentUpload("Affidavit", affidavit, (file) {
          setState(() {
            affidavit = file;
          });
        }),
        const SizedBox(height: 10),

        _buildDocumentUpload("Other Documents", otherDocuments, (file) {
          setState(() {
            otherDocuments = file;
          });
        }),
        const SizedBox(height: 10),

        _buildDocumentUpload("Photo ID", photoId, (file) {
          setState(() {
            photoId = file;
          });
        }),
      ],
    );
  }

  Widget _buildDocumentUpload(
      String label, File? file, Function(File) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                file != null ? file.path.split('/').last : 'No file selected',
                style:
                    TextStyle(color: file != null ? Colors.green : Colors.grey),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => pickImage(ImageSource.camera, onSelected),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library),
              onPressed: () => pickImage(ImageSource.gallery, onSelected),
            ),
          ],
        ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              "File selected: ${file.path}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
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
}

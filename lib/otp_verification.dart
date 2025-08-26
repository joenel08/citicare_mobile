import 'package:citicare/global_url.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class OtpVerificationPage extends StatefulWidget {
  final String contactInfo;

  const OtpVerificationPage({super.key, required this.contactInfo});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());

  Timer? _timer;
  int _start = 10; // 10 minutes in seconds
  bool _showResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _showResend = false;
    });

    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _showResend = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  String formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> resendOtp() async {
    // Reset the timer
    setState(() {
      _start = 10;
      _showResend = false;
    });
    startTimer();

    // Add your resend OTP logic here
    // For example:
    // Uri resendOtpUri = buildUri('resend_otp.php');
    // final response = await http.post(
    //   resendOtpUri,
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     "contact_info": widget.contactInfo,
    //   }),
    // );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP has been resent!")),
    );
  }

  Future<void> verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    print(widget.contactInfo);
    print(otp);
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit OTP.")),
      );
      return;
    }

    Uri verifyOtpUri = buildUri('users/verify_otp.php');

    final response = await http.post(
      verifyOtpUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contact_info": widget.contactInfo,
        "otp": otp,
      }),
    );
    print(jsonEncode({
      "contact_info": widget.contactInfo,
      "otp": otp,
    }));

    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      // Cancel timer if verification is successful
      _timer?.cancel();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account verified successfully!")),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${data['message']}")),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.green.shade700, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                "Enter the 6-digit OTP sent to",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                widget.contactInfo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        counterText: "",
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Timer display - only show if timer is still running
              if (!_showResend) ...[
                Text(
                  "Resend OTP in ${formatTime(_start)}",
                  style: TextStyle(
                    fontSize: 16,
                    color: _start < 60 ? Colors.grey : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Verify",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 15),
              // Resend section - only show when timer expires
              if (_showResend)
                Column(
                  children: [
                    const Text(
                      "Didn't receive code?",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: resendOtp,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green[700]!),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          "Resend OTP",
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}

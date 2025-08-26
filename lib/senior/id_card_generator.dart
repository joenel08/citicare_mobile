import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

class IDCardGeneratorPage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const IDCardGeneratorPage({super.key, required this.profile});

  @override
  State<IDCardGeneratorPage> createState() => _IDCardGeneratorPageState();
}

class _IDCardGeneratorPageState extends State<IDCardGeneratorPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _captureAndSaveCard() async {
    setState(() => _isSaving = true);

    try {
      // Capture the card image first (before requesting permissions)
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Handle permissions
      if (await Permission.storage.request().isGranted) {
        // For Android 10 and below
        await _saveImage(pngBytes);
      } else if (await Permission.manageExternalStorage.request().isGranted) {
        // For Android 11 and above
        await _saveImage(pngBytes);
      } else {
        // If permissions are permanently denied
        if (await Permission.storage.isPermanentlyDenied ||
            await Permission.manageExternalStorage.isPermanentlyDenied) {
          _showPermissionDeniedDialog();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveImage(Uint8List pngBytes) async {
    final result = await SaverGallery.saveImage(
      pngBytes,
      quality: 100,
      fileName: "senior_id_card_${DateTime.now().millisecondsSinceEpoch}",
      skipIfExists: false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(result.isSuccess
              ? '✅ ID card saved to gallery!'
              : '❌ Failed to save ID card')),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Storage permission is needed to save ID cards. '
            'Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    const cardWidth = 336.0;
    const cardHeight = 213.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Image.asset(
          'assets/logo/citicare_white.png',
          height: 28,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: [
        //   IconButton(
        //     icon: _isSaving
        //         ? const CircularProgressIndicator()
        //         : const Icon(Icons.download),
        //     onPressed: _isSaving ? null : _captureAndSaveCard,
        //   )
        // ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: RepaintBoundary(
            key: _cardKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Text("Identification Card Preview",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
                const SizedBox(height: 6),
                // Front ID Design
                _buildFrontDesign(p, cardWidth, cardHeight),
                const SizedBox(height: 20),
                // Back ID Design
                _buildBackDesign(p, cardWidth, cardHeight),
                const SizedBox(height: 20),

                SizedBox(
                  width: cardWidth,
                  child: ElevatedButton(
                    onPressed: _captureAndSaveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Download ID Card",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontDesign(
      Map<String, dynamic> p, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        // borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/ID_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo/santa maria-seal.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                    const Column(
                      children: [
                        Text("Republic of the Philippines",
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("Municipality of Cabagan",
                            style: TextStyle(fontSize: 10)),
                        Text("SENIOR CITIZEN ID",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (p['qr_code'] != null)
                      Image.network(p['qr_code'],
                          width: 40,
                          height: 40,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.qr_code)),
                  ],
                ),
                const SizedBox(height: 8),
                // Main Content
                Expanded(
                  child: Row(
                    children: [
                      // Left: Details
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${p['first_name']} ${p['last_name']}"
                                    .toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const Text("Name", style: TextStyle(fontSize: 8)),
                              const SizedBox(height: 6),
                              Text("Date of Birth: ${p['birthdate']}",
                                  style: const TextStyle(fontSize: 10)),
                              const SizedBox(height: 6),
                              Text(
                                  "Address: ${p['barangay']}, ${p['municipality']}",
                                  style: const TextStyle(fontSize: 10)),
                              const Spacer(),
                              // White box for signature
                              Container(
                                width: double.infinity,
                                height: 30,
                                color: Colors.white,
                                // margin: const EdgeInsets.only(bottom: 4),
                              ),

                              const Divider(color: Colors.black),
                              const Center(
                                child: Text("Signature / Thumbmark",
                                    style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right: Photo and ID #
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                color: Colors.grey[200],
                              ),
                              child: p['photo_id'] != null
                                  ? Image.network(p['photo_id'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, size: 40))
                                  : const Icon(Icons.person, size: 40),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p['idCard_no'] ?? "PENDING",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const Text("ID No.", style: TextStyle(fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackDesign(Map<String, dynamic> p, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        // borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/ID_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.white),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "BENEFITS AND PRIVILEGES UNDER REPUBLIC ACT NO. 9257",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Benefits list (with adjusted font size to fit)
                const Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      "• Free medical/dental, diagnostic & laboratory fees in all government facilities\n"
                      "• 20% discount on purchase of medicines\n"
                      "• 20% discount in Hotels, Restaurants, Recreation Centers\n"
                      "• 20% discounts on theaters and concert halls\n"
                      "• 20% discounts on medical services in private facilities\n"
                      "• 20% discounts in fare for domestic transportation\n\n"
                      "Only for the exclusive use of Senior Citizens. Misuse is punishable by law.",
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ),

                // Legal notice

                // Signatures
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // White box for signature
                        Container(
                          width: 150, // Adjust width as needed
                          height: 30,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 4),
                        ),

                        const Text("Rosario P. Canceran"),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1),
                          child: const Text(
                            "OSCA Head",
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // White box for signature
                        Container(
                          width: 150, // Adjust width as needed
                          height: 30,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 4),
                        ),
                        const Text("Hilario G. Pagauitan"),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1),
                          child: const Text(
                            "Municipal Mayor",
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

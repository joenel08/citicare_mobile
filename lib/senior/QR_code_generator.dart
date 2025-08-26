import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:saver_gallery/saver_gallery.dart';

class QRCodePreviewPage extends StatelessWidget {
  final String qrCodeUrl;

  const QRCodePreviewPage({super.key, required this.qrCodeUrl});

  String _getCleanUrl() {
    // If URL is already complete, use it as-is
    if (qrCodeUrl.startsWith('http')) {
      return qrCodeUrl;
    }
    // Otherwise combine with base URL (shouldn't happen after fixing _fetchProfileData)
    return 'http://192.168.100.4/citicare/${qrCodeUrl.replaceAll(RegExp(r'^/|/$'), '')}';
  }

  Future<void> _downloadQRCode(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final cleanUrl = _getCleanUrl();
      print('Downloading from: $cleanUrl');
      final response = await http.get(Uri.parse(cleanUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final filename = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';

        final result = await SaverGallery.saveImage(
          bytes,
          fileName: filename,
          skipIfExists: false,
        );

        Navigator.pop(context);

        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code saved to gallery!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to save QR code: ${result.errorMessage}')),
          );
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to download QR code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 280.0;
    final cleanUrl = _getCleanUrl();
    print('Displaying image from: $cleanUrl');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Image.asset(
          'assets/logo/citicare_white.png',
          height: 28,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Text("QR Code Preview",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            Image.network(
              cleanUrl,
              width: 300,
              height: 300,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator();
              },
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  children: [
                    const Text('Failed to load QR code'),
                    Text('URL: $cleanUrl',
                        style: const TextStyle(fontSize: 10)),
                    Text('Error: $error', style: const TextStyle(fontSize: 10)),
                  ],
                );
              },
            ),
            SizedBox(
              width: cardWidth,
              child: Text(
                  "You may download the QR Code above and use it as intended.",
                  textAlign: TextAlign.center, // ✅ centers the text
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: cardWidth,
              child: ElevatedButton(
                onPressed: () => _downloadQRCode(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Download QR Code",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

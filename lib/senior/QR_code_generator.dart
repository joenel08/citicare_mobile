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
    return 'http://192.168.100.4:8080/citicare/${qrCodeUrl.replaceAll(RegExp(r'^/|/$'), '')}';
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
    final cleanUrl = _getCleanUrl();
    print('Displaying image from: $cleanUrl');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your QR Code'),
        backgroundColor: const Color(0xFF3ECB6C),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _downloadQRCode(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECB6C),
              ),
              child: const Text('Download QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}

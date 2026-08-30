import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRViewExample extends StatelessWidget {
  const QRViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code")),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final barcodes = capture.barcodes;

          if (barcodes.isEmpty) return;

          final rawValue = barcodes.first.rawValue;

          if (rawValue == null) return;

          try {
            final scannedJson = jsonDecode(rawValue);
            Navigator.pop(context, scannedJson);
          } catch (e) {
            Navigator.pop(context, null);
          }
        },
      ),
    );
  }
}

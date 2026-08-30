import 'dart:convert';
import 'package:central_stadard_cpb/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'transfer_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String qrData = "";

  @override
  void initState() {
    super.initState();
    _generateQrData();
  }

  Future<void> _generateQrData() async {
    try {
      final data = await ApiService.getProfile();
      final qrJson = {
        "bank": "Central Standard CPB",
        "accountNumber": data['accountNumber'],
        "name": data['name'],
      };

      setState(() {
        qrData = jsonEncode(qrJson);
      });
    } catch (e) {
      print("Error generating QR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("QR Code", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.black)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("My Receive QR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A6E79))),
            const SizedBox(height: 20),
            if (qrData.isEmpty)
              const CircularProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: QrImageView(data: qrData, size: 250),
              ),
            const SizedBox(height: 50),
            SizedBox(
              width: 250,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: const Text("Scan to Send", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A6E79), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  final scannedData = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QRViewExample()));
                  if (scannedData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransferPage(
                          prefillBank: scannedData["bank"],
                          prefillAccountNumber: scannedData["accountNumber"],
                          prefillName: scannedData["name"],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

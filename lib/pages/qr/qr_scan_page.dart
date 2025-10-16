// lib/pages/qr_scan_page.dart
import 'dart:async';
import 'package:agys_depo_yonetim/services/qr_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'qr_view_page.dart';
import 'qr_bind_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  final QrService _service = QrService(useMock: true);
  bool _handling = false;
  String? _last;

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_handling) return;
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    if (_last == raw) return;
    setState(() {
      _handling = true;
      _last = raw;
    });
    try {
      final info = await _service.fetchInfo(raw);
      final role = await _service.resolveRole();
      if (!mounted) return;
      if (info != null) {
        // Kayıt var → görüntüleme veya sayım
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QrViewPage(code: raw, info: info, role: role),
          ),
        );
      } else {
        // Yeni bağlama
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QrBindPage(code: raw, service: _service),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _handling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Tara')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          if (_handling)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Text('İşleniyor...'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

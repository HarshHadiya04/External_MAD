import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:loyalty_card_wallet/services/camera_service.dart';
import 'package:loyalty_card_wallet/screens/qr_scanner_screen.dart';

class BarcodeService {
  // Scan barcode using device camera
  static Future<String> scanBarcode(BuildContext context) async {
    try {
      // Check if we're on desktop
      if (CameraService.isDesktop) {
        return await _scanWithQRScanner(context);
      } else {
        // Try using the QR scanner first
        try {
          return await _scanWithQRScanner(context);
        } catch (e) {
          // Fallback to flutter_barcode_scanner for mobile devices
          debugPrint('Falling back to flutter_barcode_scanner: $e');
          return await _scanWithMobileCamera();
        }
      }
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
      return '';
    }
  }

  // Scan using mobile camera via flutter_barcode_scanner
  static Future<String> _scanWithMobileCamera() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#FF6666', // Line color
      'Cancel', // Cancel button text
      true, // Show flash icon
      ScanMode.BARCODE, // Scan mode (barcode, QR, etc)
    );
    
    // Cancel was pressed or error occurred
    if (barcodeScanRes == '-1') {
      return '';
    }
    
    return barcodeScanRes;
  }

  // Scan using the QR scanner
  static Future<String> _scanWithQRScanner(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
    
    return result ?? '';
  }
} 
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final mobile_scanner.MobileScannerController controller = mobile_scanner.MobileScannerController();
  bool isScanning = true;
  mobile_scanner.BarcodeCapture? capturedBarcode;
  bool isProcessingImage = false;
  
  // We'll use a single instance of the barcode scanner
  final _barcodeScanner = mlkit.BarcodeScanner(
    formats: [
      mlkit.BarcodeFormat.qrCode,
      mlkit.BarcodeFormat.aztec,
      mlkit.BarcodeFormat.codabar,
      mlkit.BarcodeFormat.code39,
      mlkit.BarcodeFormat.code93,
      mlkit.BarcodeFormat.code128,
      mlkit.BarcodeFormat.dataMatrix,
      mlkit.BarcodeFormat.ean8,
      mlkit.BarcodeFormat.ean13,
      mlkit.BarcodeFormat.itf,
      mlkit.BarcodeFormat.pdf417,
      mlkit.BarcodeFormat.unknown,
    ]
  );
  
  @override
  void dispose() {
    controller.dispose();
    // Safely close the barcode scanner
    try {
      _barcodeScanner.close();
    } catch (e) {
      print('Error closing barcode scanner: $e');
      // Ignore the error as we're disposing anyway
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state as mobile_scanner.TorchState) {
                  case mobile_scanner.TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case mobile_scanner.TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state as mobile_scanner.CameraFacing) {
                  case mobile_scanner.CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case mobile_scanner.CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          mobile_scanner.MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          
          // Overlay
          CustomPaint(
            painter: ScannerOverlay(
              overlayColour: Colors.black.withOpacity(0.5),
            ),
            child: Container(),
          ),
          
          // Success Screen
          if (capturedBarcode != null && !isScanning)
            Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 100,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Code Detected!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    capturedBarcode?.barcodes.first.rawValue ?? 'Unknown code',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context, 
                        capturedBarcode?.barcodes.first.rawValue ?? '',
                      );
                    },
                    child: const Text('Use This Code'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        capturedBarcode = null;
                        isScanning = true;
                      });
                      controller.start();
                    },
                    child: const Text('Scan Again'),
                  ),
                ],
              ),
            ),
          
          // Scan Instructions
          if (isScanning)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 50),
                child: const Text(
                  'Position the QR code inside the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
          // Upload button
          if (isScanning && !isProcessingImage)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: _pickImageAndScan,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Upload QR Code'),
                ),
              ),
            ),
            
          // Loading overlay
          if (isProcessingImage)
            Container(
              color: Colors.black54,
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing image...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _pickImageAndScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      
      if (image == null) return;
      
      setState(() {
        isProcessingImage = true;
      });
      
      // IMPORTANT: Do NOT call controller.stop() which causes MissingPluginException
      // Instead, we'll process the image independently
      
      // Create an InputImage from the picked file
      final inputImage = mlkit.InputImage.fromFilePath(image.path);
      
      try {
        // Process the image with Google ML Kit using our existing scanner instance
        final mlkitBarcodes = await _barcodeScanner.processImage(inputImage);
        
        // Log detected barcodes for debugging
        if (mlkitBarcodes.isNotEmpty) {
          print('Found ${mlkitBarcodes.length} barcodes:');
          for (var barcode in mlkitBarcodes) {
            print('  Value: ${barcode.rawValue}, Format: ${barcode.format}');
          }
        } else {
          print('No barcodes detected in the image');
        }
        
        if (mlkitBarcodes.isNotEmpty && mlkitBarcodes.first.rawValue != null) {
          // Convert ML Kit barcodes to MobileScanner format
          final mobileBarcodes = mlkitBarcodes.map((barcode) => 
            mobile_scanner.Barcode(
              rawValue: barcode.rawValue ?? '',
              format: _convertBarcodeFormat(barcode.format),
              displayValue: barcode.rawValue,
              corners: const [],
              type: mobile_scanner.BarcodeType.text,
            )
          ).toList();
          
          setState(() {
            capturedBarcode = mobile_scanner.BarcodeCapture(
              barcodes: mobileBarcodes,
              image: null,
            );
            isScanning = false;
            isProcessingImage = false;
          });
        } else {
          _handleScanFailure('No barcode found in the image. Try an image with a clearer QR code or barcode.');
        }
      } catch (e) {
        print('Error processing barcode: $e');
        _handleScanFailure('Error processing image. Please try again with a different image.');
      }
    } catch (e) {
      print('Error picking image: $e');
      _handleScanFailure('Error accessing image: $e');
    }
  }
  
  // Helper method to convert between ML Kit and Mobile Scanner barcode formats
  mobile_scanner.BarcodeFormat _convertBarcodeFormat(mlkit.BarcodeFormat format) {
    // Map between formats based on their names
    switch (format) {
      case mlkit.BarcodeFormat.qrCode:
        return mobile_scanner.BarcodeFormat.qrCode;
      case mlkit.BarcodeFormat.aztec:
        return mobile_scanner.BarcodeFormat.aztec;
      case mlkit.BarcodeFormat.codabar:
        return mobile_scanner.BarcodeFormat.codabar;
      case mlkit.BarcodeFormat.code39:
        return mobile_scanner.BarcodeFormat.code39;
      case mlkit.BarcodeFormat.code93:
        return mobile_scanner.BarcodeFormat.code93;
      case mlkit.BarcodeFormat.code128:
        return mobile_scanner.BarcodeFormat.code128;
      case mlkit.BarcodeFormat.dataMatrix:
        return mobile_scanner.BarcodeFormat.dataMatrix;
      case mlkit.BarcodeFormat.ean8:
        return mobile_scanner.BarcodeFormat.ean8;
      case mlkit.BarcodeFormat.ean13:
        return mobile_scanner.BarcodeFormat.ean13;
      case mlkit.BarcodeFormat.itf:
        return mobile_scanner.BarcodeFormat.itf;
      case mlkit.BarcodeFormat.pdf417:
        return mobile_scanner.BarcodeFormat.pdf417;
      // UPC-A and UPC-E are not directly supported in mobile_scanner
      default:
        return mobile_scanner.BarcodeFormat.unknown;
    }
  }
  
  // Helper method to handle scan failures
  void _handleScanFailure(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    
    setState(() {
      isProcessingImage = false;
    });
    
    // Only try to restart the scanner if we're still mounted and scanning
    if (mounted && isScanning) {
      try {
        // Use a delayed restart to avoid race conditions
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && isScanning) {
            controller.start();
          }
        });
      } catch (e) {
        print('Error restarting scanner: $e');
        // If this fails, we're still in a usable state
      }
    }
  }

  void _onDetect(mobile_scanner.BarcodeCapture capture) {
    if (!isScanning || isProcessingImage) return;
    
    if (capture.barcodes.isNotEmpty && 
        capture.barcodes.first.rawValue != null &&
        capture.barcodes.first.rawValue!.isNotEmpty) {
      
      setState(() {
        capturedBarcode = capture;
        isScanning = false;
      });
      controller.stop();
    }
  }
}

// Custom painter for the scanner overlay
class ScannerOverlay extends CustomPainter {
  ScannerOverlay({required this.overlayColour});

  final Color overlayColour;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final scanArea = width * 0.7;
    final left = (width - scanArea) / 2;
    final top = (height - scanArea) / 2;
    final right = left + scanArea;
    final bottom = top + scanArea;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height));
    
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, scanArea, scanArea),
          topLeft: const Radius.circular(10),
          topRight: const Radius.circular(10),
          bottomLeft: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
      );
    
    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    
    canvas.drawPath(finalPath, Paint()..color = overlayColour);
    
    // Draw scanning area border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Draw corners
    const cornerLength = 30.0;
    
    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );
    
    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right, top)
        ..lineTo(right, top + cornerLength),
      borderPaint,
    );
    
    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom)
        ..lineTo(left + cornerLength, bottom),
      borderPaint,
    );
    
    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) => false;
} 
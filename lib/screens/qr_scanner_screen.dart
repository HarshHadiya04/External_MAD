import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  BarcodeCapture? capturedBarcode;

  @override
  void dispose() {
    controller.dispose();
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
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
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
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
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
          MobileScanner(
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
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;
    
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
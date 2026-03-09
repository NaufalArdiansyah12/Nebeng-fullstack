import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'qr_result_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool isScanning = true;
  bool flashOn = false;
  bool _isSwitchingCamera = false;
  bool _cameraError = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _safeSwitchCamera() async {
    if (_isSwitchingCamera || !mounted) return;

    setState(() {
      _isSwitchingCamera = true;
      _cameraError = false;
    });

    try {
      await cameraController.switchCamera();
    } catch (_) {
      _cameraError = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera tidak tersedia atau gagal beralih'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSwitchingCamera = false);
      }
    }
  }

  Future<void> _safeToggleTorch() async {
    if (_cameraError) return;

    try {
      await cameraController.toggleTorch();
      if (mounted) setState(() => flashOn = !flashOn);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flash tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning || capture.barcodes.isEmpty) return;

    final String? qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() => isScanning = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRResultPage(qrData: qrData),
      ),
    ).then((_) {
      if (mounted) setState(() => isScanning = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// CAMERA
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _cameraError = true);
              });

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Kamera tidak tersedia atau gagal dibuka',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          await cameraController.start();
                          if (mounted) {
                            setState(() => _cameraError = false);
                          }
                        } catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kamera gagal dibuka'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Coba lagi',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),

          /// TOP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                color: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: Icon(
                        flashOn ? Icons.flash_on : Icons.flash_off,
                        color: _cameraError ? Colors.grey : Colors.white,
                      ),
                      onPressed: _cameraError ? null : _safeToggleTorch,
                    ),
                    IconButton(
                      onPressed:
                          _isSwitchingCamera || _cameraError
                              ? null
                              : _safeSwitchCamera,
                      icon: _isSwitchingCamera
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cameraswitch,
                              color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// SCAN FRAME
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 16),
              child: isScanning
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Arahkan kamera ke QR Code',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_service.dart';

class CameraScannerService implements ScannerService {
  @override
  ScannerType get type => ScannerType.camera;

  final _controller = StreamController<ScannerResult>.broadcast();
  late final MobileScannerController _mobileScannerController;

  @override
  Future<void> initialize() async {
    _mobileScannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 500,
    );
  }

  // --- EVENTO QUE VIENE DESDE EL WIDGET ---

  void onBarcodeDetected(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;

    final raw = capture.barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;

    final result = validateCode(raw);
    _controller.add(result);
  }

  @override
  Stream<ScannerResult> get onScan => _controller.stream;

  @override
  ScannerResult validateCode(String code) {
    final normalized = code.trim();
    if (normalized.isEmpty) {
      return ScannerResult(
        rawCode: code,
        isValid: false,
        message: 'Código vacío',
      );
    }

    return ScannerResult(
      rawCode: code,
      normalizedCode: normalized,
      isValid: true,
    );
  }

  @override
  Future<void> dispose() async {
    // _mobileScannerController.dispose();
    // _controller.close();
  }

  MobileScannerController get mobileScannerController =>
      _mobileScannerController;
}

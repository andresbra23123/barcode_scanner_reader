import 'dart:async';

enum ScannerMode { loadConfirmation, deliveryConfirmation }

enum ScanningType { document, item }

enum ScannerType { laser, camera }

enum ScannerStatus {
  notScanned,
  notLoaded,
  laserScanned,
  cameraScanned,
  manualScanned
}

abstract class ScannerService {
  ScannerType get type;

  /// Inicializar el servicio (abrir camera, registrar listeners...)
  Future<void> initialize();

  /// Stream de resultados de escaneos
  Stream<ScannerResult> get onScan;

  /// Validar código (codeBar / expedition)
  ScannerResult validateCode(String code);

  /// Liberar recursos
  Future<void> dispose();
}

class ScannerResult {
  final String rawCode;
  final String? normalizedCode;
  final bool isValid;
  final String? message;

  ScannerResult({
    required this.rawCode,
    this.normalizedCode,
    this.isValid = false,
    this.message,
  });

  @override
  String toString() =>
      'ScannerResult(raw: $rawCode, valid: $isValid, msg: $message)';
}

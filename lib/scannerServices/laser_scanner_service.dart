import 'dart:async';

import 'package:flutter/services.dart';

import 'scanner_service.dart';

class LaserScannerService implements ScannerService {
  @override
  ScannerType get type => ScannerType.laser;

  // Singleton pattern
  static LaserScannerService? _instance;
  static LaserScannerService get instance {
    _instance ??= LaserScannerService._();
    return _instance!;
  }

  LaserScannerService._();

  StreamController<ScannerResult>? _controller;
  static const EventChannel _channel = EventChannel('scanner_channel');
  StreamSubscription<dynamic>? _subscription;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    // Si ya está inicializado, no hacer nada
    if (_isInitialized && _subscription != null) {
      return;
    }

    // Si el controller está cerrado o es null, crear uno nuevo
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<ScannerResult>.broadcast();
    }

    // Solo crear una nueva suscripción si no existe
    if (_subscription == null) {
      _subscription = _channel.receiveBroadcastStream().listen(
        (dynamic code) {
          if (code is String && _controller != null && !_controller!.isClosed) {
            final result = validateCode(code);
            _controller!.add(result);
          }
        },
        onError: (error) {
          if (_controller != null && !_controller!.isClosed) {
            _controller!.addError(error);
          }
        },
      );
      _isInitialized = true;
    }
  }

  @override
  Stream<ScannerResult> get onScan {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<ScannerResult>.broadcast();
    }
    return _controller!.stream;
  }

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
  Future<void> dispose() async {}
}

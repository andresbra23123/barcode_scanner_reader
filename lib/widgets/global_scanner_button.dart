import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart';

import '../scannerServices/scanner_manager.dart';
import '../scannerServices/scanner_service.dart';

class GlobalScannerButton extends StatelessWidget {
  final double? size;
  final IconData? icon;
  final bool isScannerEnabled;

  final void Function(ScannerResult scannerResult)? onScan;
  final Future<void> Function()? onOpenCamera;

  const GlobalScannerButton({
    super.key,
    this.size = 28,
    this.icon = Icons.qr_code_scanner_sharp,
    this.onScan,
    this.onOpenCamera,
    required this.isScannerEnabled,
  });

  @override
  Widget build(BuildContext context) {
    if (isScannerEnabled) {
      return _GlobalScannerButton(
        size: size,
        icon: icon!,
        onScan: onScan,
        onOpenCamera: onOpenCamera,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

/// Widget global reutilizable para activar ambos modos de escaneo
/// - Láser: modo por defecto (listener de teclado)
/// - Cámara: al navegar a la pantalla del escáner de cámara
class _GlobalScannerButton extends StatefulWidget {
  final double? size;
  final IconData? icon;

  /// 🔥 Callback que devuelve el código escaneado por LÁSER
  final void Function(ScannerResult scannerResult)? onScan;
  final Future<void> Function()? onOpenCamera;
  const _GlobalScannerButton({
    this.size,
    this.onScan,
    this.onOpenCamera,
    this.icon,
  });

  @override
  State<_GlobalScannerButton> createState() => _GlobalScannerButtonState();
}

class _GlobalScannerButtonState extends State<_GlobalScannerButton> {
  final ScannerManager _manager = ScannerManager();
  StreamSubscription<ScannerResult>? _sub;

  @override
  void initState() {
    super.initState();
    _initLaser();
  }

  Future<void> _initLaser() async {
    await _manager.initialize(preferred: ScannerType.laser);

    _sub?.cancel();
    _sub = _manager.service.onScan.listen((result) {
      // 🔥 Verificar que el widget esté montado y la ruta esté activa
      if (!mounted) return;

      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) {
        // Si la ruta no está activa, ignorar el escaneo
        return;
      }

      if (result.isValid && result.rawCode.isNotEmpty) {
        widget.onScan?.call(result); // 🔥 devuelve código al caller
      }
    });
  }

  Future<void> _stopLaser() async {
    _manager.dispose(); // 🔥 desactiva el láser totalmente
    _sub?.cancel();
  }

  @override
  void dispose() {
    _stopLaser();
    super.dispose();
  }

  Future<void> _openCamera() async {
    await _stopLaser(); // 🔥 se DESACTIVA el láser cuando entras a cámara

    if (!mounted) return;
    await widget.onOpenCamera?.call();

    // 🔥 Al volver, reactivar el láser automáticamente
    await _initLaser();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: IconButton(
        onPressed: _openCamera,
        icon: Icon(widget.icon!, size: widget.size!),
      ),
    );
  }
}

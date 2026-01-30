import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

import '../cubit/scanner_cubit.dart';
import '../scannerServices/camera_scanner_service.dart';
import '../scannerServices/scanner_manager.dart';
import '../scannerServices/scanner_service.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  late final ScannerManager _manager = ScannerManager();
  StreamSubscription<ScannerResult>? _sub;

  late Future<void> _initCameraFuture;

  ScannerResult? scannerResult;

  @override
  void initState() {
    super.initState();
    _initCameraFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _manager.initialize(preferred: ScannerType.camera);

      _sub?.cancel();
      _sub = _manager.service.onScan.listen((result) async {
        if (result.isValid && result.rawCode.isNotEmpty) {
          setState(() => scannerResult = result);
        }
      });
    } catch (_) {}
  }

  Future<void> _stopCamera() async {
    _manager.dispose();
    _sub?.cancel();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initCameraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error al inicializar la cámara: ${snapshot.error}'),
            ),
          );
        }

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: _AppBar(
              cameraService: _manager.service as CameraScannerService,
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                _MobileScanner(
                  cameraService: _manager.service as CameraScannerService,
                ),
                ItemCode(scannerResult: scannerResult),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.cameraService});

  final CameraScannerService cameraService;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.close, color: Colors.white, size: 28),
      ),
      title: Text('Escaner', style: TextStyle(color: Colors.white)),
      centerTitle: true,
      actions: [
        // Botón de flash
        IconButton(
          onPressed: cameraService.mobileScannerController.toggleTorch,
          icon: Icon(
            cameraService.mobileScannerController.torchEnabled
                ? Icons.flash_off
                : Icons.flash_on,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _MobileScanner extends StatelessWidget {
  const _MobileScanner({required this.cameraService});

  final CameraScannerService cameraService;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: cameraService.mobileScannerController,
          onDetect: cameraService.onBarcodeDetected,
        ),
        const _Corners(),
      ],
    );
  }
}

class _Corners extends StatelessWidget {
  const _Corners();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          children: [
            _corner(
              const BorderSide(color: Colors.white, width: 4),
              Alignment.topLeft,
            ),
            _corner(
              const BorderSide(color: Colors.white, width: 4),
              Alignment.topRight,
            ),
            _corner(
              const BorderSide(color: Colors.white, width: 4),
              Alignment.bottomLeft,
            ),
            _corner(
              const BorderSide(color: Colors.white, width: 4),
              Alignment.bottomRight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(BorderSide side, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border(
            left:
                alignment == Alignment.topLeft ||
                        alignment == Alignment.bottomLeft
                    ? side
                    : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                        alignment == Alignment.bottomRight
                    ? side
                    : BorderSide.none,
            top:
                alignment == Alignment.topLeft ||
                        alignment == Alignment.topRight
                    ? side
                    : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                        alignment == Alignment.bottomRight
                    ? side
                    : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class ItemCode extends StatefulWidget {
  final ScannerResult? scannerResult;

  const ItemCode({super.key, required this.scannerResult});

  @override
  State<ItemCode> createState() => _ItemCodeState();
}

class _ItemCodeState extends State<ItemCode> {
  bool _isProcessing = false;

  @override
  void didUpdateWidget(ItemCode oldWidget) {
    if (!_isProcessing) {
      _handleCodeBarVerification();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _handleCodeBarVerification() async {
    log('scannerResult: ${widget.scannerResult}');
    if (widget.scannerResult == null) {
      return;
    }
    if (_isProcessing) {
      return;
    }

    // Marcar como procesando para evitar múltiples llamadas
    setState(() {
      _isProcessing = true;
    });

    log('scannerResult: ${widget.scannerResult}');

    _vibrate();
    try {
      await context.read<ScannerCubit>().scanCode(
        scannerResult: widget.scannerResult!,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _vibrate() async {
    var hasVibrate = await Vibration.hasVibrator();
    if (hasVibrate) {
      await Vibration.vibrate(duration: 500);
    }
  }

  // Método para reanudar el escaneo
  void _resumeScanning() {
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      top: 0,
      left: 0,
      right: 0,
      child: BlocSelector<ScannerCubit, ScannerState, ScannerResult?>(
        selector: (state) {
          return state.scannerResult;
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                  child: ListTile(
                    title: Text('Código'),
                    subtitle: Text(state?.rawCode ?? 'xxxxxxxxxx'),
                  ),
                ),

                if (_isProcessing)
                  ElevatedButton(
                    onPressed: _resumeScanning,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        const Icon(Icons.barcode_reader),
                        Text('Continuar escaneando'),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

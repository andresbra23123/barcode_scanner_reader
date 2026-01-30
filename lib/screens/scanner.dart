import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/scanner_cubit.dart';
import '../scannerServices/scanner_service.dart';
import '../widgets/global_scanner_button.dart';
import 'camera_scanner.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        actions: [
          GlobalScannerButton(
            onOpenCamera: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CameraScannerScreen()),
              );
            },
            onScan: (scannerResult) async {
              await context.read<ScannerCubit>().scanCode(
                scannerResult: scannerResult,
              );
            },
            isScannerEnabled: true,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BlocSelector<ScannerCubit, ScannerState, ScannerResult?>(
            selector: (state) {
              return state.scannerResult;
            },
            builder: (context, state) {
              return Card(
                child: ListTile(
                  title: Text('Código'),
                  subtitle: Text(state?.rawCode ?? 'xxxxxxxxxx'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

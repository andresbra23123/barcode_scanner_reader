import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../scannerServices/scanner_service.dart';

part 'scanner_state.dart';

class ScannerCubit extends Cubit<ScannerState> {
  ScannerCubit() : super(const ScannerState());

  Future<void> scanCode({required ScannerResult scannerResult}) async {
    emit(ScannerState(scannerResult: scannerResult));
  }
}

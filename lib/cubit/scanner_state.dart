part of 'scanner_cubit.dart';

class ScannerState extends Equatable {
  final ScannerResult? scannerResult;

  const ScannerState({this.scannerResult});

  @override
  List<Object?> get props => [scannerResult];
}

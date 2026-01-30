import 'camera_scanner_service.dart';
import 'laser_scanner_service.dart';
import 'scanner_service.dart';

class ScannerManager {
  ScannerService? _service;

  ScannerService get service => _service!;

  Future<void> initialize({required ScannerType preferred}) async {
    // print(
    //     '>>>>>>>>>>>>> initializing scanner manager $preferred, $screenName <<<<<<<<<<<<');
    _service = _createService(preferred);
    await _service!.initialize();
  }

  ScannerService _createService(ScannerType type) {
    switch (type) {
      case ScannerType.laser:
        return LaserScannerService.instance;
      case ScannerType.camera:
        return CameraScannerService();
    }
  }

  Future<void> dispose() async {
    // print(
    //     '>>>>>>>>>>>>> disposing scanner manager ${service.type}, $screenName <<<<<<<<<<<<');
    await _service?.dispose();
    _service = null;
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const _serviceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const _charUuid    = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

class BleService {
  BluetoothDevice? _device;

  final _dataController = StreamController<List<double>>.broadcast();
  final _stateController = StreamController<bool>.broadcast();

  Stream<List<double>> get dataStream  => _dataController.stream;
  Stream<bool>         get stateStream => _stateController.stream;

  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    await device.connect(autoConnect: false);
    _stateController.add(true);

    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid.toString().toLowerCase() == _serviceUuid) {
        for (final c in s.characteristics) {
          if (c.uuid.toString().toLowerCase() == _charUuid) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen((bytes) {
              if (bytes.length < 24) return;
              final bd = ByteData.sublistView(Uint8List.fromList(bytes));
              final data = List.generate(6, (i) => bd.getFloat32(i * 4, Endian.little).toDouble());
              _dataController.add(data);
            });
          }
        }
      }
    }

    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _stateController.add(false);
      }
    });
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _stateController.add(false);
  }

  void dispose() {
    _dataController.close();
    _stateController.close();
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/ble_service.dart';
import '../core/inference_service.dart';
import '../core/tts_service.dart';
import 'settings_viewmodel.dart';

export '../core/inference_service.dart' show VoiceLabel, PredictionResult;

enum AppState { scanning, connecting, connected, disconnected }

class HomeViewModel extends ChangeNotifier {
  final SettingsViewModel settings;

  HomeViewModel({required this.settings});

  final _ble       = BleService();
  final _inference = InferenceService();
  final _tts       = TtsService();

  AppState          _appState    = AppState.disconnected;
  PredictionResult? _lastResult;
  List<double>      _rawFeatures = [];
  String            _statusMsg   = 'Chưa kết nối';
  bool              _ready       = false;
  int               _predCount   = 0;

  bool _showFeatures = true;
  bool _showHistory  = true;

  final List<PredictionResult> _history = [];

  AppState          get appState    => _appState;
  PredictionResult? get lastResult  => _lastResult;
  List<double>      get rawFeatures => _rawFeatures;
  String            get statusMsg   => _statusMsg;
  bool              get ready       => _ready;
  int               get predCount   => _predCount;
  bool              get showFeatures => _showFeatures;
  bool              get showHistory  => _showHistory;
  bool              get isConnected => _appState == AppState.connected;
  List<PredictionResult> get history => List.unmodifiable(_history);

  StreamSubscription? _dataSub;
  StreamSubscription? _stateSub;

  Future<void> init() async {
    await _inference.init();
    await _tts.init();
    _ready = true;
    notifyListeners();
  }

  void toggleFeatures() { _showFeatures = !_showFeatures; notifyListeners(); }
  void toggleHistory()  { _showHistory  = !_showHistory;  notifyListeners(); }

  void startScan() {
    _appState  = AppState.scanning;
    _statusMsg = 'Đang tìm kiếm...';
    notifyListeners();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == "ESP32-Sensor") {
          FlutterBluePlus.stopScan();
          _connect(r.device);
          break;
        }
      }
    });

    Future.delayed(const Duration(seconds: 9), () {
      if (_appState == AppState.scanning) {
        _appState  = AppState.disconnected;
        _statusMsg = 'Không tìm thấy thiết bị';
        notifyListeners();
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    _appState  = AppState.connecting;
    _statusMsg = 'Đang kết nối...';
    notifyListeners();

    await _ble.connect(device);

    _appState  = AppState.connected;
    _statusMsg = 'ESP32-Sensor';
    notifyListeners();

    _stateSub = _ble.stateStream.listen((connected) {
      if (!connected) {
        _appState   = AppState.disconnected;
        _statusMsg  = 'Mất kết nối';
        _lastResult = null;
        notifyListeners();
      }
    });

    _dataSub = _ble.dataStream.listen((data) {
      _rawFeatures = data;
      final result = _inference.predict(data);

      _lastResult = result;
      _predCount++;

      _history.insert(0, result);
      if (_history.length > 20) _history.removeLast();

      notifyListeners();

      // TTS: đọc nếu không mute, không phải silent, confidence đủ cao
      if (!settings.isMuted &&
          result.label != VoiceLabel.silent &&
          result.confidence >= 0.80) {
        _tts.speak(result.ttsText);
      }
    });
  }

  Future<void> disconnect() async {
    await _dataSub?.cancel();
    await _stateSub?.cancel();
    await _ble.disconnect();
    _appState   = AppState.disconnected;
    _statusMsg  = 'Đã ngắt kết nối';
    _lastResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _stateSub?.cancel();
    _ble.dispose();
    _inference.close();
    _tts.stop();
    super.dispose();
  }
}
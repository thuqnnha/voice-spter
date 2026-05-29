import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../core/ble_service.dart';
import '../core/inference_service.dart';
import '../core/tts_service.dart';
import 'settings_viewmodel.dart';

export '../core/inference_service.dart'
    show VoiceLabel, PredictionResult;


enum AppState { scanning, connecting, connected, disconnected }

enum StatusType {
  notConnected,
  scanning,
  connecting,
  connected,
  disconnected,
  deviceNotFound,
  connectionLost,
}

class HomeViewModel extends ChangeNotifier {
  final SettingsViewModel settings;
  void _onSettingsChanged() {
    notifyListeners();
    _tts.setLanguage(settings.language);
  }

  HomeViewModel({required this.settings}) {
    settings.addListener(_onSettingsChanged);
  }

  final _ble       = BleService();
  final _inference = InferenceService();
  final _tts       = TtsService();

  AppState          _appState    = AppState.disconnected;
  PredictionResult? _lastResult;
  List<double>      _rawFeatures = [];
  StatusType _status = StatusType.notConnected;
  bool              _ready       = false;
  int               _predCount   = 0;

  VoiceLabel? _lastSpoken;//

  bool _showFeatures = true;
  bool _showHistory  = true;

  final List<PredictionResult> _history = [];

  AppState          get appState    => _appState;
  PredictionResult? get lastResult  => _lastResult;
  List<double>      get rawFeatures => _rawFeatures;
  bool              get ready       => _ready;
  int               get predCount   => _predCount;
  bool              get showFeatures => _showFeatures;
  bool              get showHistory  => _showHistory;
  bool              get isConnected => _appState == AppState.connected;
  List<PredictionResult> get history => List.unmodifiable(_history);

  StreamSubscription? _dataSub;
  StreamSubscription? _stateSub;

  String getStatusText() {
    switch (_status) {
      case StatusType.notConnected:
        return settings.strings.notConnected;

      case StatusType.scanning:
        return settings.strings.scanning;

      case StatusType.connecting:
        return settings.strings.connecting;

      case StatusType.disconnected:
        return settings.strings.disconnected;

      case StatusType.deviceNotFound:
        return settings.strings.deviceNotFound;

      case StatusType.connectionLost:
        return settings.strings.connectionLost;

      case StatusType.connected:
        return 'ESP32-Sensor';
    }
  }

  Future<void> init() async {
    await _inference.init();
    await _tts.init();
    _ready = true;
    notifyListeners();
  }

  void toggleFeatures() { _showFeatures = !_showFeatures; notifyListeners(); }
  void toggleHistory()  { _showHistory  = !_showHistory;  notifyListeners(); }

  void startScan() {
    _appState = AppState.scanning;
    _status = StatusType.scanning;
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
        _appState = AppState.disconnected;
        _status = StatusType.deviceNotFound;
        notifyListeners();
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    _appState = AppState.connecting;
    _status = StatusType.connecting;
    notifyListeners();

    await _ble.connect(device);

    _appState = AppState.connected;
    _status = StatusType.connected;
    notifyListeners();

    _stateSub = _ble.stateStream.listen((connected) {
      if (!connected) {
        _appState   = AppState.disconnected;
        _status = StatusType.connectionLost;
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
      // if (!settings.isMuted && result.confidence >= 0.40) {
      //   _tts.speak(result.ttsText);
      // }

      if(!settings.isMuted && (result.confidence >= 0.40 ||
          (result.label == VoiceLabel.sai && result.confidence >= 0.10)) && result.label != _lastSpoken
      ){

        _lastSpoken =
            result.label;

        _tts.speak(
            result.ttsText
        );

      }
    });
  }

  Future<void> disconnect() async {
    await _dataSub?.cancel();
    await _stateSub?.cancel();
    await _ble.disconnect();
    _appState   = AppState.disconnected;
    _status = StatusType.disconnected;
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
    settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
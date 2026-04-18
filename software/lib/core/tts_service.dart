import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async => _tts.stop();
}
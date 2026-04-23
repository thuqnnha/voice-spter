import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final _tts = FlutterTts();
  bool _isReady = false;

  Future<void> init() async {
    try {
      var langs = await _tts.getLanguages;

      debugPrint("Available TTS languages: $langs");

      if (langs.contains("vi-VN")) {
        await _tts.setLanguage("vi-VN");
      } else {
        debugPrint("vi-VN not found → fallback en-US");
        await _tts.setLanguage("en-US");
      }

      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _isReady = true;
    } catch (e) {
      debugPrint("TTS init error: $e");
      _isReady = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isReady || text.isEmpty) return;

    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS speak error: $e");
    }
  }

  Future<void> stop() async => _tts.stop();
}
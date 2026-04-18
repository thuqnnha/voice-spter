// TFLite + StandardScaler
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum VoiceLabel { silent, yes, no }

class PredictionResult {
  final VoiceLabel label;
  final double confidence;
  final List<double> probs;

  const PredictionResult({
    required this.label,
    required this.confidence,
    required this.probs,
  });

  String get labelText => switch (label) {
    VoiceLabel.silent => 'Im lặng',
    VoiceLabel.yes    => 'Có',
    VoiceLabel.no     => 'Không',
  };

  String get ttsText => switch (label) {
    VoiceLabel.silent => '',
    VoiceLabel.yes    => 'Có',
    VoiceLabel.no     => 'Không',
  };
}

class _StandardScaler {
  late List<double> mean;
  late List<double> std;

  Future<void> load() async {
    final raw  = await rootBundle.loadString('assets/scaler_params.json');
    final json = jsonDecode(raw);
    mean = List<double>.from(json['mean']);
    std  = List<double>.from(json['std']);
  }

  List<double> transform(List<double> x) =>
      List.generate(x.length, (i) => (x[i] - mean[i]) / std[i]);
}

class InferenceService {
  late Interpreter _interpreter;
  final _scaler = _StandardScaler();

  Future<void> init() async {
    await _scaler.load();
    _interpreter = await Interpreter.fromAsset('assets/model.tflite');
  }

  PredictionResult predict(List<double> rawFeatures) {
    final scaled = _scaler.transform(rawFeatures);
    final input  = [scaled];
    final output = List.generate(1, (_) => List.filled(3, 0.0));

    _interpreter.run(input, output);

    final probs = output[0];
    int maxIdx  = 0;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > probs[maxIdx]) maxIdx = i;
    }

    final label = VoiceLabel.values[maxIdx];
    return PredictionResult(
      label:      label,
      confidence: probs[maxIdx],
      probs:      probs,
    );
  }

  void close() => _interpreter.close();
}
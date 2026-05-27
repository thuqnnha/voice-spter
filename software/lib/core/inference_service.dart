// TFLite + StandardScaler
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum VoiceLabel {
  khong,   // 0
  dung,      // 1
  sai,      // 2
}

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
    VoiceLabel.khong => 'Không',
    VoiceLabel.dung    => 'Đúng',
    VoiceLabel.sai    => 'Sai',
  };

  String get ttsText => switch (label) {
    VoiceLabel.khong => 'Không',
    VoiceLabel.dung    => 'Đúng',
    VoiceLabel.sai    => 'Sai',
  };
}

class _StandardScaler {
  late List<double> mean;
  late List<double> std;

  Future<void> load() async {
    final raw  = await rootBundle.loadString('assets/scaler_params5.json');
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

  VoiceLabel? _lastLabel;

  Future<void> init() async {
    await _scaler.load();
    _interpreter = await Interpreter.fromAsset('assets/model5.tflite');

    // debugPrint("INPUT: "
    //     "${_interpreter.getInputTensor(0).shape}");
    // debugPrint(
    //     "OUTPUT: "
    //         "${_interpreter.getOutputTensor(0).shape}"
    // );
  }

  // PredictionResult predict(List<double> rawFeatures) {
  //   final scaled = _scaler.transform(rawFeatures);
  //
  //   debugPrint("raw = $rawFeatures");
  //   debugPrint("scaled = $scaled");
  //
  //   final input  = [scaled];
  //   final output = List.generate(1, (_) => List.filled(4, 0.0));
  //
  //   _interpreter.run(input, output);
  //
  //   debugPrint("probs = ${output[0]}");
  //
  //   final probs = output[0].sublist(0,3);
  //
  //   int maxIdx  = 0;
  //   for (int i = 1; i < probs.length; i++) {
  //     if (probs[i] > probs[maxIdx]) maxIdx = i;
  //   }
  //
  //   final label = VoiceLabel.values[maxIdx];
  //   return PredictionResult(
  //     label:      label,
  //     confidence: probs[maxIdx],
  //     probs:      probs,
  //   );
  // }

  PredictionResult predict(List<double> rawFeatures) {
    final scaled = _scaler.transform(rawFeatures);

    debugPrint("raw = $rawFeatures");
    debugPrint("scaled = $scaled");

    final input  = [scaled];
    final output = List.generate(1, (_) => List.filled(4, 0.0));

    _interpreter.run(input, output);

    debugPrint("raw probs = ${output[0]}");

    final probs = output[0].sublist(0,3);

// =======================
// BOOST class "Sai"
// =======================

    probs[2] *= 2.0;     // tăng xác suất Sai lên 2 lần

// tránh >100%
    double sum =
        probs[0] +
            probs[1] +
            probs[2];

    probs[0] /= sum;
    probs[1] /= sum;
    probs[2] /= sum;

    debugPrint(
        "boost probs = $probs"
    );

// =======================
// RULE:
// nếu Sai >10%
// và Không <70%
// => ép thành Sai
// =======================

    int maxIdx=0;

    for(
    int i=1;
    i<probs.length;
    i++
    ){
      if(
      probs[i]
          >
          probs[maxIdx]
      ){
        maxIdx=i;
      }
    }


// ưu tiên Sai
    if(

    probs[2] > 0.10

        &&

        probs[0] < 0.70

    ){

      maxIdx = 2;

    }


// confidence thấp
// giữ label cũ

    if(

    probs[maxIdx]
        <
        0.20

        &&

        _lastLabel
            !=
            null

    ){

      maxIdx =
          _lastLabel!
              .index;

    }


    _lastLabel =
    VoiceLabel
        .values[
    maxIdx
    ];

    final label = VoiceLabel.values[maxIdx];
    return PredictionResult(
      label:      label,
      confidence: probs[maxIdx],
      probs:      probs,
    );
  }


  void close() => _interpreter.close();
}
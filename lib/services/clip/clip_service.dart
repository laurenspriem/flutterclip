import 'dart:developer' as devtools show log;
import 'dart:io';
import 'dart:math' as math show min, max;
import 'dart:typed_data' show Uint8List;

import 'package:flutterclip/services/clip/model_config.dart';
import 'package:flutterclip/utils/image.dart';
import 'package:flutterclip/utils/ml_input_output.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClipService {
  ClipService._({required this.config});

  final ModelConfig config;

  static Future<ClipService> create() async {
    // In the line below, we can change the model to use
    final config = clipImageOpenai; // clipImageOpenai //
    final clipDetector = ClipService._(config: config);
    await clipDetector.loadModel();
    return clipDetector;
  }

  final outputShapes = <List<int>>[];
  final outputTypes = <TensorType>[];

  Interpreter? interpreter;

  List<Object> get props => [];

  int get getAddress => interpreter!.address;

  late int originalImageWidth;
  late int originalImageHeight;

  Future<void> loadModel() async {
    devtools.log('loadModel is called');

    try {
      final interpreterOptions = InterpreterOptions();

      // Use XNNPACK Delegate
      if (Platform.isAndroid) {
        interpreterOptions.addDelegate(XNNPackDelegate());
      }

      // Use GPU Delegate
      // doesn't work on emulator
      if (Platform.isAndroid) {
        interpreterOptions.addDelegate(GpuDelegateV2());
      }

      // Use Metal Delegate
      if (Platform.isIOS) {
        interpreterOptions.addDelegate(GpuDelegate());
      }

      // Load model from assets
      interpreter = interpreter ??
          await Interpreter.fromAsset(
            config.modelPath,
            options: interpreterOptions,
          );

      // Get tensor input shape [1, 128, 128, 3]
      final inputTensors = interpreter!.getInputTensors().first;
      devtools.log('CLIP Input Tensors: $inputTensors');
      // Get tensour output shape [1, 896, 16]
      final outputTensors = interpreter!.getOutputTensors();
      final outputTensor = outputTensors.first;
      devtools.log('CLIP Output Tensors: $outputTensor');

      for (var tensor in outputTensors) {
        outputShapes.add(tensor.shape);
        outputTypes.add(tensor.type);
      }
      devtools.log('CLIP loadModel is finished');
    } catch (e) {
      devtools.log('CLIP Error while creating interpreter: $e');
    }
  }

  List<List<List<num>>> getPreprocessedImage(image_lib.Image image) {
    devtools.log('CLIP preprocessing is called');
    final embeddingOptions = config.clipOptions;

    originalImageWidth = image.width;
    originalImageHeight = image.height;
    devtools.log(
      'originalImageWidth: $originalImageWidth, originalImageHeight: $originalImageHeight',
    );

    // Resize image for model input
    final imageInput = image_lib.copyResize(
      image,
      width: embeddingOptions.inputWidth,
      height: embeddingOptions.inputHeight,
      interpolation: image_lib.Interpolation
          .linear, // can choose `bicubic` if more accuracy is needed. But this is slow, and adds little if bilinear is already used earlier (which is the case)
    );

    // TODO: Add correct normalization (see https://colab.research.google.com/github/openai/clip/blob/master/notebooks/Interacting_with_CLIP.ipynb)

    // Get image matrix representation [inputWidt, inputHeight, 3]
    final imageMatrix = createInputMatrixFromImageChannelsFirst(imageInput, normalize: true);
    devtools.log('Preprocessing is finished');

    // Check the content of imageMatrix for anything suspicious!
    // for (var i = 0; i < imageMatrix.length; i++) {
    //   for (var j = 0; j < imageMatrix[i].length; j++) {
    //     devtools.log('Pixel at [$i, $j]: ${imageMatrix[i][j]}');
    //   }
    // }

    return imageMatrix;
  }

  // TODO: Make the predict function run in separate thread with use of isolate-interpreter: https://github.com/tensorflow/flutter-tflite/issues/52
  List predict(Uint8List imageData) {
    assert(interpreter != null);

    final image = convertDataToImageImage(imageData);

    devtools.log('outputShapes: $outputShapes');

    final stopwatch = Stopwatch()..start();

    final inputImageMatrix =
        getPreprocessedImage(image); // [inputWidt, inputHeight, 3]
    final input = [inputImageMatrix];

    final output = createEmptyOutputMatrix(outputShapes[0]);

    devtools.log('CLIP interpreter.run is called');
    // Run inference
    final clipInterpreterStopwatch = Stopwatch()..start();
    interpreter!.run(input, output);
    clipInterpreterStopwatch.stop();
    devtools.log('CLIP interpreter.run is finished, in ${clipInterpreterStopwatch.elapsedMilliseconds}ms');

    // Get output tensors
    final embedding = output[0] as List;

    stopwatch.stop();
    devtools.log(
      'CLIP predict() executed in ${stopwatch.elapsedMilliseconds}ms',
    );

    devtools
        .log('CLIP results (only first few numbers): embedding ${embedding.sublist(0, 5)}');
    devtools.log(
      'Mean of embedding: ${embedding.cast<num>().reduce((a, b) => a + b) / embedding.length}',
    );
    devtools.log(
      'Max of embedding: ${embedding.cast<num>().reduce(math.max)}',
    );
    devtools.log(
      'Min of embedding: ${embedding.cast<num>().reduce(math.min)}',
    );

    return embedding;
  }
}

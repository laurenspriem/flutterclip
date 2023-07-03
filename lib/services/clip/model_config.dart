import 'package:flutterclip/services/clip/clip_options.dart';
import 'package:flutterclip/constants/model_file.dart';

class ModelConfig {
  final String modelPath;
  final ClipOptions clipOptions;

  ModelConfig({
    required this.modelPath,
    required this.clipOptions,
  });
}

final ModelConfig clipImageOpenai = ModelConfig(
  modelPath: ModelFile.clipImageOpenai,
  clipOptions: ClipOptions(
    inputWidth: 224,
    inputHeight: 224,
  ),
);

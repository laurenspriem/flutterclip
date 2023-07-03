
class ClipOptions {
  final int inputWidth;
  final int inputHeight;
  final List<num> normalizeMeans;
  final List<num> normalizeStd;
  final List<int> outputShape;

  ClipOptions({
    required this.inputWidth,
    required this.inputHeight,
    List<num>? normalizeMeans,
    List<num>? normalizeStd,
    List<int>? outputShape
  }) : normalizeMeans = normalizeMeans ?? [0.48145466, 0.4578275, 0.40821073],
       normalizeStd = normalizeStd ?? [0.26862954, 0.26130258, 0.27577711],
       outputShape = [1, 512];
}
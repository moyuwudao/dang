/// 实时转写结果
class RealtimeTranscriptionResult {
  final String text;
  final bool isFinal;
  final Duration beginTime;
  final Duration endTime;

  const RealtimeTranscriptionResult({
    required this.text,
    required this.isFinal,
    required this.beginTime,
    required this.endTime,
  });

  @override
  String toString() {
    return 'RealtimeTranscriptionResult(text: $text, isFinal: $isFinal, beginTime: $beginTime, endTime: $endTime)';
  }
}

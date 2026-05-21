import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'app_logger.dart';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final StreamController<List<double>> _amplitudeController = StreamController<List<double>>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<List<int>> _audioStreamController = StreamController<List<int>>.broadcast();

  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  Duration _currentDuration = Duration.zero;
  List<double> _amplitudes = [];
  StreamSubscription? _streamSubscription;
  String? _currentFilePath;
  IOSink? _fileSink;

  Stream<List<double>> get amplitudeStream => _amplitudeController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<List<int>>? get audioStream => !_audioStreamController.isClosed
      ? _audioStreamController.stream
      : null;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<String> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingDir = Directory(p.join(directory.path, 'recordings'));

    if (!await recordingDir.exists()) {
      await recordingDir.create(recursive: true);
    }

    final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    final filePath = p.join(recordingDir.path, fileName);
    _currentFilePath = filePath;

    // 创建文件用于写入音频数据
    final file = File(filePath);
    _fileSink = file.openWrite();

    // 使用 startStream 获取音频流
    // 优化：使用较小的缓冲区以提高实时性
    const recordConfig = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    );

    final audioStream = await _audioRecorder.startStream(recordConfig);

    _streamSubscription = audioStream.listen(
      (Uint8List data) {
        // 转发到音频流控制器（供实时转写使用）
        _audioStreamController.add(data.toList());
        // 同时写入文件
        _fileSink?.add(data);
      },
      onError: (e) {
        AppLogger().e('Recording', 'Audio stream error: $e');
      },
      onDone: () {
        // Audio stream completed
      },
    );

    _startDurationTimer();
    _startAmplitudeListener();

    return filePath;
  }

  Future<String?> stopRecording() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _currentDuration = Duration.zero;
    _amplitudes = [];

    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _fileSink?.close();
    _fileSink = null;

    await _audioRecorder.stop();

    if (_currentFilePath != null) {
      await _addWavHeader(_currentFilePath!);
    }

    return _currentFilePath;
  }

  Future<void> _addWavHeader(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final pcmSize = await file.length();
    if (pcmSize == 0) return;

    const sampleRate = 16000;
    const bitsPerSample = 16;
    const numChannels = 1;
    const byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    const blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = pcmSize;
    final fileSize = dataSize + 36;

    // 构建 WAV header
    final header = Uint8List(44);
    final headerView = ByteData.sublistView(header);

    header.setRange(0, 4, 'RIFF'.codeUnits);
    headerView.setUint32(4, fileSize, Endian.little);
    header.setRange(8, 12, 'WAVE'.codeUnits);

    header.setRange(12, 16, 'fmt '.codeUnits);
    headerView.setUint32(16, 16, Endian.little);
    headerView.setUint16(20, 1, Endian.little);
    headerView.setUint16(22, numChannels, Endian.little);
    headerView.setUint32(24, sampleRate, Endian.little);
    headerView.setUint32(28, byteRate, Endian.little);
    headerView.setUint16(32, blockAlign, Endian.little);
    headerView.setUint16(34, bitsPerSample, Endian.little);

    header.setRange(36, 40, 'data'.codeUnits);
    headerView.setUint32(40, dataSize, Endian.little);

    // 流式写入：先写 header 到临时文件，再追加 PCM 数据，最后替换原文件
    final tempPath = '$filePath.tmp';
    final tempFile = File(tempPath);
    final tempSink = tempFile.openWrite();
    try {
      tempSink.add(header);
      await tempSink.flush();
      await tempSink.close();

      // 使用流式追加 PCM 数据，避免将整个 PCM 读入内存
      final pcmStream = file.openRead();
      final appendSink = tempFile.openWrite(mode: FileMode.append);
      try {
        await pcmStream.pipe(appendSink);
      } catch (e) {
        await appendSink.close();
        rethrow;
      }

      // 替换原文件
      await file.delete();
      await tempFile.rename(filePath);
      AppLogger().d('Recording', 'WAV header added: ${dataSize + 44} bytes');
    } catch (e) {
      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      AppLogger().e('Recording', 'WAV header add failed: $e');
    }
  }

  Future<void> pauseRecording() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    await _audioRecorder.pause();
  }

  Future<void> resumeRecording() async {
    await _audioRecorder.resume();
    _startDurationTimer();
    _startAmplitudeListener();
  }

  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _currentDuration = Duration.zero;
    _amplitudes = [];

    // 停止音频流并关闭/删除文件
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _fileSink?.close();
    _fileSink = null;

    await _audioRecorder.stop();

    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _currentFilePath = null;
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentDuration += const Duration(seconds: 1);
      _durationController.add(_currentDuration);
    });
  }

  void _startAmplitudeListener() {
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        final amp = await _audioRecorder.getAmplitude();
        _amplitudes.add(amp.current);
        if (_amplitudes.length > 100) {
          _amplitudes.removeAt(0);
        }
        _amplitudeController.add(List.from(_amplitudes));
      } catch (e) {
        // Ignore amplitude errors
      }
    });
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger().e('Recording', 'Failed to delete recording: $e');
    }
  }

  Future<Duration> getAudioDuration(String filePath) async {
    final player = AudioPlayer();
    try {
      final duration = await player.setFilePath(filePath);
      return duration ?? Duration.zero;
    } catch (e) {
      AppLogger().e('Recording', 'Failed to get audio duration: $e');
      return Duration.zero;
    } finally {
      await player.dispose();
    }
  }

  void dispose() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _streamSubscription?.cancel();
    _fileSink?.close();
    _amplitudeController.close();
    _durationController.close();
    _audioStreamController.close();
    _audioRecorder.dispose();
  }
}

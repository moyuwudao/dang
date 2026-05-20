import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

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
    const recordConfig = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
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
        debugPrint('Audio stream error: $e');
      },
      onDone: () {
        debugPrint('Audio stream done');
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

    final pcmBytes = await file.readAsBytes();
    if (pcmBytes.isEmpty) return;

    const sampleRate = 16000;
    const bitsPerSample = 16;
    const numChannels = 1;
    const byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    const blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = pcmBytes.length;
    final fileSize = dataSize + 36;

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

    final wavBytes = Uint8List(header.length + pcmBytes.length);
    wavBytes.setRange(0, header.length, header);
    wavBytes.setRange(header.length, wavBytes.length, pcmBytes);

    await file.writeAsBytes(wavBytes);
    debugPrint('WAV header added: ${wavBytes.length} bytes, duration ~${dataSize ~/ byteRate}s');
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
      debugPrint('Failed to delete recording: $e');
    }
  }

  Future<Duration> getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      final duration = await player.setFilePath(filePath);
      await player.dispose();
      return duration ?? Duration.zero;
    } catch (e) {
      debugPrint('Failed to get audio duration: $e');
      return Duration.zero;
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

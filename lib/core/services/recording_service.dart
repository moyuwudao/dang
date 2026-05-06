import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final StreamController<List<double>> _amplitudeController = StreamController<List<double>>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();

  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  Duration _currentDuration = Duration.zero;
  List<double> _amplitudes = [];

  Stream<List<double>> get amplitudeStream => _amplitudeController.stream;
  Stream<Duration> get durationStream => _durationController.stream;

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

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: filePath,
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

    return await _audioRecorder.stop();
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
    await _audioRecorder.stop();
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
    _amplitudeController.close();
    _durationController.close();
    _audioRecorder.dispose();
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class AudioChunkInfo {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final int size;

  const AudioChunkInfo({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.size,
  });

  String get durationText {
    final start =
        '${startTime.inMinutes}:${(startTime.inSeconds % 60).toString().padLeft(2, '0')}';
    final end =
        '${endTime.inMinutes}:${(endTime.inSeconds % 60).toString().padLeft(2, '0')}';
    return '$start - $end';
  }
}

class AudioProcessor {
  static const int chunkDurationSeconds = 30;
  static const int wavHeaderSize = 44;

  String getMimeType(String filePath) {
    if (filePath.endsWith('.wav')) return 'audio/wav';
    if (filePath.endsWith('.m4a')) return 'audio/mp4';
    if (filePath.endsWith('.aac')) return 'audio/aac';
    if (filePath.endsWith('.ogg')) return 'audio/ogg';
    if (filePath.endsWith('.flac')) return 'audio/flac';
    if (filePath.endsWith('.mp3')) return 'audio/mp3';
    return 'audio/mp3';
  }

  int getWavDurationSeconds(Uint8List wavBytes) {
    if (wavBytes.length < wavHeaderSize) return 0;

    final dataView = ByteData.sublistView(wavBytes);

    final riff = String.fromCharCodes(wavBytes.sublist(0, 4));
    if (riff != 'RIFF') return 0;

    final sampleRate = dataView.getUint32(24, Endian.little);
    final bitsPerSample = dataView.getUint16(34, Endian.little);
    final numChannels = dataView.getUint16(22, Endian.little);
    final dataSize = dataView.getUint32(40, Endian.little);

    if (sampleRate == 0 || bitsPerSample == 0 || numChannels == 0) return 0;

    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    if (byteRate == 0) return 0;

    return dataSize ~/ byteRate;
  }

  List<Uint8List> splitWavFile(Uint8List wavBytes) {
    if (wavBytes.length < wavHeaderSize) return [];

    final dataView = ByteData.sublistView(wavBytes);

    final riff = String.fromCharCodes(wavBytes.sublist(0, 4));
    if (riff != 'RIFF') {
      debugPrint('Invalid WAV file: missing RIFF header');
      return [];
    }

    final sampleRate = dataView.getUint32(24, Endian.little);
    final bitsPerSample = dataView.getUint16(34, Endian.little);
    final numChannels = dataView.getUint16(22, Endian.little);
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);

    if (byteRate == 0) return [];

    final chunkByteSize = byteRate * chunkDurationSeconds;
    final originalDataSize = dataView.getUint32(40, Endian.little);
    const originalDataStart = wavHeaderSize;

    if (originalDataSize <= chunkByteSize) {
      return [wavBytes];
    }

    final chunks = <Uint8List>[];
    int offset = 0;
    int chunkIndex = 0;

    while (offset < originalDataSize) {
      final currentChunkSize = (offset + chunkByteSize <= originalDataSize)
          ? chunkByteSize
          : originalDataSize - offset;

      final chunkTotalSize = currentChunkSize + wavHeaderSize - 8;
      const subchunk1Size = 16;
      final blockAlign = numChannels * (bitsPerSample ~/ 8);

      final header = Uint8List(wavHeaderSize);
      final headerView = ByteData.sublistView(header);

      header.setRange(0, 4, 'RIFF'.codeUnits);
      headerView.setUint32(4, chunkTotalSize, Endian.little);
      header.setRange(8, 12, 'WAVE'.codeUnits);

      header.setRange(12, 16, 'fmt '.codeUnits);
      headerView.setUint32(16, subchunk1Size, Endian.little);
      headerView.setUint16(20, 1, Endian.little);
      headerView.setUint16(22, numChannels, Endian.little);
      headerView.setUint32(24, sampleRate, Endian.little);
      headerView.setUint32(28, byteRate, Endian.little);
      headerView.setUint16(32, blockAlign, Endian.little);
      headerView.setUint16(34, bitsPerSample, Endian.little);

      header.setRange(36, 40, 'data'.codeUnits);
      headerView.setUint32(40, currentChunkSize, Endian.little);

      final chunk = Uint8List(wavHeaderSize + currentChunkSize);
      chunk.setRange(0, wavHeaderSize, header);
      chunk.setRange(wavHeaderSize, wavHeaderSize + currentChunkSize,
          wavBytes, originalDataStart + offset);

      chunks.add(chunk);
      debugPrint(
          'Chunk ${chunkIndex + 1}: ${currentChunkSize ~/ byteRate}s, ${(chunk.length / 1024).toStringAsFixed(0)}KB');

      offset += currentChunkSize;
      chunkIndex++;
    }

    if (chunks.isEmpty) {
      throw Exception('音频分片失败: 文件有效但分片后为空，可能是文件太小或格式异常');
    }
    debugPrint('Split WAV into ${chunks.length} chunks');
    return chunks;
  }

  List<Uint8List> splitAudioByBytes(Uint8List audioBytes, String mimeType) {
    if (audioBytes.isEmpty) return [];

    debugPrint(
        'Non-WAV file detected ($mimeType), cannot split compressed audio');
    return [audioBytes];
  }

  Future<List<AudioChunkInfo>> getAudioChunks(String audioFilePath) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('音频文件不存在: $audioFilePath');
    }

    final audioBytes = await file.readAsBytes();
    final mimeType = getMimeType(audioFilePath);

    List<Uint8List> chunks;
    if (audioFilePath.endsWith('.wav')) {
      final totalDuration = getWavDurationSeconds(audioBytes);
      chunks = splitWavFile(audioBytes);
      return List.generate(chunks.length, (index) {
        final startTime = index * chunkDurationSeconds;
        final endTime = (index + 1) * chunkDurationSeconds;
        final actualEndTime = endTime > totalDuration ? totalDuration : endTime;
        return AudioChunkInfo(
          index: index,
          startTime: Duration(seconds: startTime),
          endTime: Duration(seconds: actualEndTime),
          size: chunks[index].length,
        );
      });
    } else {
      return [
        AudioChunkInfo(
          index: 0,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 0),
          size: audioBytes.length,
        ),
      ];
    }
  }
}

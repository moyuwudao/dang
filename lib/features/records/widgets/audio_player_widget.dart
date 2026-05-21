import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/theme/app_colors.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final String audioPath;

  const AudioPlayerWidget({super.key, required this.audioPath});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _errorMessage;
  bool _fileExists = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  int? _fileSize;
  bool _isDragging = false;

  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final file = File(widget.audioPath);
      final exists = await file.exists();
      if (!exists) {
        if (mounted) {
          setState(() {
            _fileExists = false;
            _errorMessage = '音频文件不存在: ${widget.audioPath}';
          });
        }
        AppLogger().e('AudioPlayer', '文件不存在: ${widget.audioPath}');
        return;
      }

      if (mounted) {
        setState(() {
          _fileExists = true;
          _isLoading = true;
        });
      }

      final stat = await file.stat();
      _fileSize = stat.size;

      if (stat.size < 44) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = '音频文件无效(太小: ${stat.size} bytes)';
          });
        }
        return;
      }

      final duration = await _audioPlayer.setFilePath(widget.audioPath);

      _durationSub = _audioPlayer.durationStream.listen(
        (duration) {
          if (mounted && duration != null) {
            setState(() {
              _duration = duration;
            });
          }
        },
        onError: (e) {
          AppLogger().e('AudioPlayer', 'durationStream error: $e');
        },
      );

      _positionSub = _audioPlayer.positionStream.listen(
        (position) {
          if (mounted && !_isDragging && position.inSeconds != _position.inSeconds) {
            setState(() {
              _position = position;
            });
          }
        },
        onError: (e) {
          AppLogger().e('AudioPlayer', 'positionStream error: $e');
        },
      );

      _playerStateSub = _audioPlayer.playerStateStream.listen(
        (state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
              if (state.processingState == ProcessingState.completed) {
                _isPlaying = false;
                _position = Duration.zero;
              }
            });
          }
        },
        onError: (e) {
          AppLogger().e('AudioPlayer', 'playerStateStream error: $e');
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger().e('AudioPlayer', '初始化失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '播放器初始化失败: $e';
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '播放失败: $e';
      });
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> _shareAudio() async {
    try {
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = '音频文件不存在';
        });
        return;
      }

      await Share.shareXFiles(
        [XFile(widget.audioPath)],
        text: '畅记录音',
      );
    } catch (e) {
      setState(() {
        _errorMessage = '分享失败: $e';
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_fileExists || _isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final fileSize = _fileSize ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.audio_file, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '音频播放',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (fileSize > 0)
                  Text(
                    _formatFileSize(fileSize),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) {
                      final box = context.findRenderObject() as RenderBox;
                      final localPosition =
                          box.globalToLocal(details.globalPosition);
                      final width = box.size.width;
                      final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
                      final position = Duration(
                        milliseconds:
                            (ratio * _duration.inMilliseconds).toInt(),
                      );
                      _seek(position);
                    },
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? (_position.inMilliseconds /
                                  _duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0,
                      onChangeStart: (_) {
                        setState(() {
                          _isDragging = true;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _position = Duration(
                            milliseconds:
                                (value * _duration.inMilliseconds).toInt(),
                          );
                        });
                      },
                      onChangeEnd: (value) {
                        setState(() {
                          _isDragging = false;
                        });
                        final position = Duration(
                          milliseconds:
                              (value * _duration.inMilliseconds).toInt(),
                        );
                        _seek(position);
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _togglePlay,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? '暂停' : '播放'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareAudio,
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

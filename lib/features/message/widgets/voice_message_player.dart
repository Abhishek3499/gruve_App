import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isSent;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.isSent,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  static AudioPlayer? _activePlayer;

  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _isDragging = false;
  double _dragValue = 0.0;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _completeSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant VoiceMessagePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _updateSource();
    }
  }

  void _initPlayer() async {
    _audioPlayer = AudioPlayer();

    // 1. Subscribe to streams BEFORE setting the source
    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted && !_isDragging) {
        setState(() {
          _position = p;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      AppLogger.d('🔊 [VoiceMessagePlayer] onDurationChanged: $d');
      if (mounted) {
        setState(() {
          _duration = d;
        });
      }
    });

    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() {
          _isPlaying = s == PlayerState.playing;
        });
      }
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (_activePlayer == _audioPlayer) {
        _activePlayer = null;
      }
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });

    // 2. Load the initial source if not empty
    if (widget.audioUrl.isNotEmpty) {
      await _setSource();
    }
  }

  Future<void> _setSource() async {
    try {
      final source = widget.audioUrl.startsWith('http')
          ? UrlSource(widget.audioUrl)
          : DeviceFileSource(widget.audioUrl);
      await _audioPlayer.setSource(source);

      // Force get duration immediately after setting the source as stream fallback
      final d = await _audioPlayer.getDuration();
      if (d != null && d != Duration.zero && mounted) {
        AppLogger.d('🔊 [VoiceMessagePlayer] getDuration resolved: $d');
        setState(() {
          _duration = d;
        });
      }
    } catch (e) {
      AppLogger.d('💥 [VoiceMessagePlayer] Error setting audio source: $e');
    }
  }

  void _updateSource() async {
    try {
      await _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _duration = Duration.zero;
          _isDragging = false;
          _dragValue = 0.0;
        });
      }
      if (widget.audioUrl.isNotEmpty) {
        await _setSource();
      }
    } catch (e) {
      AppLogger.d('💥 [VoiceMessagePlayer] Error updating source: $e');
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (_activePlayer == _audioPlayer) {
          _activePlayer = null;
        }
      } else {
        // Pause any currently playing voice message before starting this one
        if (_activePlayer != null && _activePlayer != _audioPlayer) {
          try {
            await _activePlayer!.pause();
          } catch (e) {
            AppLogger.d('💥 [VoiceMessagePlayer] Error pausing previous player: $e');
          }
        }
        _activePlayer = _audioPlayer;
        await _audioPlayer.resume();
      }
    } catch (e) {
      AppLogger.d('💥 [VoiceMessagePlayer] Playback error: $e');
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    if (_activePlayer == _audioPlayer) {
      _activePlayer = null;
    }
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double maxVal = _duration.inMilliseconds.toDouble();
    final double currVal = _isDragging
        ? _dragValue
        : _position.inMilliseconds.toDouble().clamp(0.0, maxVal > 0 ? maxVal : 0.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white24,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Slider / Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: currVal,
                    max: maxVal > 0 ? maxVal : 1.0,
                    onChangeStart: _duration == Duration.zero ? null : (value) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = value;
                      });
                    },
                    onChanged: _duration == Duration.zero ? null : (value) {
                      setState(() {
                        _dragValue = value;
                      });
                    },
                    onChangeEnd: _duration == Duration.zero ? null : (value) async {
                      await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      setState(() {
                        _isDragging = false;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_isDragging
                            ? Duration(milliseconds: _dragValue.toInt())
                            : _position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _duration != Duration.zero ? _formatDuration(_duration) : '0:00',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

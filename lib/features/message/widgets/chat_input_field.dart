import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gruve_app/core/assets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:record/record.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String) onSendImage;
  final Function(String) onSendVoice;
  final bool isLoading;
  final TextEditingController? controller;
  final String? hintText;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendVoice,
    required this.isLoading,
    this.controller,
    this.hintText,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  late final TextEditingController _controller;
  final ImagePicker _imagePicker = ImagePicker();
  bool _ownsController = false;

  // Recording variables
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSendMessage(_controller.text.trim());
    _controller.clear();
  }

  void _showMediaBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF311B36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x4DFFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Select Media',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),

            // Options
            Row(
              children: [
                // Camera
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF72008D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Gallery
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF72008D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<String?> _cropImage(String sourcePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop / Edit Image',
            toolbarColor: const Color(0xFF72008D), // Matches theme purple
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF72008D),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop / Edit Image',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      return croppedFile?.path;
    } catch (e) {
      AppLogger.d('Error cropping image: $e');
      return null;
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final croppedPath = await _cropImage(image.path);
        if (croppedPath != null) {
          widget.onSendImage(croppedPath);
        }
      }
    } catch (e) {
      AppLogger.d('Error picking image from camera: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final croppedPath = await _cropImage(image.path);
        if (croppedPath != null) {
          widget.onSendImage(croppedPath);
        }
      }
    } catch (e) {
      AppLogger.d('Error picking image from gallery: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopAndSendRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record voice messages.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final tempDir = Directory.systemTemp;
      final filePath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _recordingSeconds = 0;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
          });
        }
      });

      setState(() {
        _isRecording = true;
      });
      AppLogger.d('🎙️ [ChatInputField] Voice recording started at $filePath');
    } catch (e) {
      AppLogger.d('💥 [ChatInputField] Failed to start voice recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      AppLogger.d('🎙️ [ChatInputField] Voice recording cancelled and discarded');
    } catch (e) {
      AppLogger.d('💥 [ChatInputField] Failed to cancel voice recording: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          widget.onSendVoice(path);
        } else {
          throw Exception('Recording file is empty or missing');
        }
      }
    } catch (e) {
      AppLogger.d('💥 [ChatInputField] Failed to stop and send recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete voice message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildRecordingRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: _cancelRecording,
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const _PulsingRecordDot(),
        const SizedBox(width: 8),
        Text(
          'Recording ${_formatDuration(_recordingSeconds)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _stopAndSendRecording,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.white, Color(0xFFFDEFFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: Image.asset(
                  AppAssets.send,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalRow() {
    return Row(
      children: [
        // Camera Icon
        GestureDetector(
          onTap: _showMediaBottomSheet,
          child: Image.asset(AppAssets.camera, height: 24, width: 24),
        ),
        const SizedBox(width: 12),

        // Text Field
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Text Message',
              hintStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Voice Icon
        GestureDetector(
          onTap: _toggleRecording,
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),

        // Send Button
        GestureDetector(
          onTap: widget.isLoading ? null : _send,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.white, Color(0xFFFDEFFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Color(0xFF6A0D81),
                      strokeWidth: 2,
                    ),
                  )
                : Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: Image.asset(
                        AppAssets.send,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 58,
        padding: const EdgeInsets.only(
          left: 16,
          right: 18,
        ),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 171, 20, 209), // Solid purple
          borderRadius: BorderRadius.circular(30),
        ),
        child: _isRecording ? _buildRecordingRow() : _buildNormalRow(),
      ),
    );
  }
}

class _PulsingRecordDot extends StatefulWidget {
  const _PulsingRecordDot();

  @override
  State<_PulsingRecordDot> createState() => _PulsingRecordDotState();
}

class _PulsingRecordDotState extends State<_PulsingRecordDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

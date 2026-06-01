import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/filter_model.dart';
import '../controller/filter_controller.dart';
import '../controller/camera_controller_service.dart';
import '../services/mode_service.dart';
import '../utils/camera_logger.dart';

class HorizontalFilterSelector extends StatefulWidget {
  const HorizontalFilterSelector({super.key});

  @override
  State<HorizontalFilterSelector> createState() =>
      _HorizontalFilterSelectorState();
}

class _HorizontalFilterSelectorState extends State<HorizontalFilterSelector> {
  final FilterController _filterController = FilterController();
  final CameraControllerService _cameraService = CameraControllerService();
  late PageController _pageController;
  int _selectedIndex = 0;
  bool _isRecordingVideo = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  StreamSubscription<bool>? _recordingSub;

  @override
  void initState() {
    super.initState();
    // Adjusted viewportFraction to make items sit closer for better overlap look
    _pageController = PageController(
      viewportFraction: 0.22,
      initialPage: _selectedIndex,
    );
    _filterController.addListener(_onFilterChanged);
    _recordingSub = _cameraService.videoRecordingStream.listen((isRecording) {
      if (!mounted) return;
      setState(() => _isRecordingVideo = isRecording);
      if (!isRecording) {
        _recordingTimer?.cancel();
        _recordingTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _filterController.removeListener(_onFilterChanged);
    _recordingSub?.cancel();
    _recordingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final index = FilterModel.availableFilters.indexOf(
      _filterController.selectedFilter,
    );

    if (index != _selectedIndex && index >= 0) {
      setState(() => _selectedIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
    _filterController.setFilter(FilterModel.availableFilters[index]);
  }

  Future<void> _captureFilteredImage() async {
    if (_isRecordingVideo || _cameraService.isRecordingVideo) return;

    CameraLogger.logUserAction('Capturing filtered image');

    try {
      final rawImage = await _cameraService.captureImage();
      if (rawImage != null && mounted) {
        final mode = ModeService().selectedMode;

        if (mode == CameraMode.story || mode == CameraMode.groove) {
          Navigator.of(
            context,
          ).pop(CameraCaptureResult(mediaPath: rawImage.path, mode: mode));
        }
      }
    } catch (e) {
      CameraLogger.log('Failed to capture filtered image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startVideoRecording() async {
    if (_isRecordingVideo || _cameraService.isCapturing) return;

    CameraLogger.logUserAction('Video recording started from capture button');
    HapticFeedback.mediumImpact();

    setState(() {
      _recordingSeconds = 0;
    });

    await _cameraService.startVideoRecording();

    if (!_cameraService.isRecordingVideo) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopVideoRecording() async {
    if (!_cameraService.isRecordingVideo) return;

    CameraLogger.logUserAction('Video recording stopped from capture button');
    HapticFeedback.lightImpact();

    _recordingTimer?.cancel();
    _recordingTimer = null;

    try {
      final video = await _cameraService.stopVideoRecording();
      if (video == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final mode = ModeService().selectedMode;
      if (mode == CameraMode.story || mode == CameraMode.groove) {
        Navigator.of(
          context,
        ).pop(CameraCaptureResult(mediaPath: video.path, mode: mode));
      }
    } catch (e) {
      CameraLogger.log('Failed to stop video recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatRecordingDuration() {
    final minutes = _recordingSeconds ~/ 60;
    final seconds = _recordingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140, // Total height of the bottom UI area
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Bottom Shadow/Gradient for visibility

          // 2. Filter Selector (PageView) - Placed below the button but interactive
          Positioned(
            bottom: 12, // Adjusted to sit near the bottom
            left: -8,
            right: -8,
            height: 100, // Give it enough height to be tappable
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: FilterModel.availableFilters.length,
              itemBuilder: (context, index) {
                final filter = FilterModel.availableFilters[index];
                final isSelected = index == _selectedIndex;

                return GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  child: Transform.scale(
                    scale: isSelected ? 1.2 : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withAlpha(150),
                                width: isSelected ? 4 : 2,
                              ),
                              color: isSelected
                                  ? _getFilterColor(filter.type).withAlpha(100)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              filter.icon,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withAlpha(200),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            filter.name.toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withAlpha(200),
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Main Capture Button - Positioned above the filter selector
          Positioned(
            bottom: 35, // Positioned above the filter circles
            child: GestureDetector(
              onTap: _captureFilteredImage,
              onLongPressStart: (_) => _startVideoRecording(),
              onLongPressEnd: (_) => _stopVideoRecording(),
              onLongPressCancel: () {
                _stopVideoRecording();
              },
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withAlpha(50),
                  border: Border.all(
                    color: _isRecordingVideo ? Colors.red : Colors.white,
                    width: 4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecordingVideo ? Colors.red : Colors.white,
                        ),
                      ),
                    ),
                    if (_isRecordingVideo)
                      const SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 3,
                        ),
                      ),
                    if (_isRecordingVideo)
                      Positioned(
                        top: -38,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatRecordingDuration(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods kept as per your original code
  Color _getFilterColor(FilterType type) {
    switch (type) {
      case FilterType.none:
        return Colors.grey.shade800;
      case FilterType.clarendon:
        return Colors.orange.shade400;
      case FilterType.gingham:
        return Colors.green.shade400;
      case FilterType.moon:
        return Colors.blue.shade300;
      case FilterType.lark:
        return Colors.blue.shade200;
      case FilterType.reyes:
        return Colors.amber.shade300;
      case FilterType.juno:
        return Colors.yellow.shade400;
      case FilterType.slumber:
        return Colors.indigo.shade300;
      case FilterType.crema:
        return Colors.brown.shade300;
      case FilterType.ludwig:
        return Colors.purple.shade400;
      case FilterType.aden:
        return Colors.blue.shade400;
      case FilterType.perpetua:
        return Colors.teal.shade400;
      case FilterType.mayfair:
        return Colors.pink.shade300;
      case FilterType.rise:
        return Colors.orange.shade300;
      case FilterType.hudson:
        return Colors.blue.shade600;
      case FilterType.valencia:
        return Colors.red.shade300;
      case FilterType.xpro2:
        return Colors.deepOrange.shade400;
      case FilterType.sepia:
        return Colors.brown.shade400;
    }
  }
}

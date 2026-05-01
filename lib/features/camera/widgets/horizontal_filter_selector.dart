import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/filter_model.dart';
import '../controller/filter_controller.dart';
import 'capture_button.dart';
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
  bool _showCaptureBadge = false;

  @override
  void initState() {
    super.initState();
    // Adjusted viewportFraction to make items sit closer for better overlap look
    _pageController = PageController(
      viewportFraction: 0.22,
      initialPage: _selectedIndex,
    );
    _filterController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterController.removeListener(_onFilterChanged);
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
    CameraLogger.logUserAction('Capturing filtered image');
    setState(() => _showCaptureBadge = true);

    try {
      final rawImage = await _cameraService.captureImage();
      if (rawImage != null && mounted) {
        final mode = ModeService().selectedMode;
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showCaptureBadge = false);
        });

        if (mode == CameraMode.story || mode == CameraMode.groove) {
          Navigator.of(
            context,
          ).pop(CameraCaptureResult(mediaPath: rawImage.path, mode: mode));
        }
      }
    } catch (e) {
      CameraLogger.log('Failed to capture filtered image: $e');
      if (mounted) {
        setState(() => _showCaptureBadge = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150, // Total height of the bottom UI area
      width: MediaQuery.of(context).size.width,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Bottom Shadow/Gradient for visibility

          // 2. Filter Selector (PageView) - Placed below the button but interactive
          Positioned(
            bottom: 10, // Adjusted to sit near the bottom
            left: 0,
            right: 0,
            height: 120, // Give it enough height to be tappable
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: FilterModel.availableFilters.length,
              itemBuilder: (context, index) {
                final filter = FilterModel.availableFilters[index];
                final isSelected = index == _selectedIndex;

                // If selected, we hide the filter icon because the Capture Button overlaps it
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 0.0 : 1.0,
                  child: GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(150),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            filter.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filter.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Main Capture Button - Positioned exactly over the center of the PageView
          Positioned(
            bottom: 25, // Aligned with the filter circles
            child: GestureDetector(
              onTap: _captureFilteredImage,
              child: Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withAlpha(50),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _cameraService.isRecordingVideo
                          ? Colors.red
                          : Colors.white,
                    ),
                  ),
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
      case FilterType.warm:
        return Colors.orange.shade400;
      case FilterType.cool:
        return Colors.blue.shade400;
      case FilterType.sepia:
        return Colors.brown.shade400;
      case FilterType.vintage:
        return Colors.amber.shade600;
      case FilterType.blackAndWhite:
        return Colors.grey.shade800;
      case FilterType.vivid:
        return Colors.pink.shade400;
      case FilterType.dramatic:
        return Colors.purple.shade600;
    }
  }
}

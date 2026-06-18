import 'dart:math';
import 'package:flutter/material.dart';
import '../../camera/models/sticker_data.dart';

class MockTrack {
  final String id;
  final String title;
  final String artist;
  final String durationStr;
  final double totalDurationSeconds;
  final Gradient coverGradient;

  const MockTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationStr,
    required this.totalDurationSeconds,
    required this.coverGradient,
  });
}

class StoryMusicPicker extends StatefulWidget {
  final StickerData? initialSticker;

  const StoryMusicPicker({
    super.key,
    this.initialSticker,
  });

  static Future<StickerData?> open(BuildContext context, {StickerData? initialSticker}) {
    return showModalBottomSheet<StickerData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StoryMusicPicker(initialSticker: initialSticker),
        );
      },
    );
  }

  @override
  State<StoryMusicPicker> createState() => _StoryMusicPickerState();
}

class _StoryMusicPickerState extends State<StoryMusicPicker> {
  final List<MockTrack> _allTracks = [
    MockTrack(
      id: '1',
      title: 'Mind Charged Body',
      artist: 'Abhishek',
      durationStr: '3:05',
      totalDurationSeconds: 185.0,
      coverGradient: const LinearGradient(colors: [Color(0xFFC358D7), Color(0xFF72008D)]),
    ),
    MockTrack(
      id: '2',
      title: 'Vibrant Energy',
      artist: 'Lofi Vibes',
      durationStr: '2:40',
      totalDurationSeconds: 160.0,
      coverGradient: const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF9500)]),
    ),
    MockTrack(
      id: '3',
      title: 'Midnight Groove',
      artist: 'Synthwave Kid',
      durationStr: '3:50',
      totalDurationSeconds: 230.0,
      coverGradient: const LinearGradient(colors: [Color(0xFF00FFCC), Color(0xFF5AC8FA)]),
    ),
    MockTrack(
      id: '4',
      title: 'Summer Breeze',
      artist: 'Tropic Beats',
      durationStr: '2:15',
      totalDurationSeconds: 135.0,
      coverGradient: const LinearGradient(colors: [Color(0xFFFFCC00), Color(0xFFFF9500)]),
    ),
    MockTrack(
      id: '5',
      title: 'Happy Steps',
      artist: 'Dance Floor',
      durationStr: '3:12',
      totalDurationSeconds: 192.0,
      coverGradient: const LinearGradient(colors: [Color(0xFF4CD964), Color(0xFF5AC8FA)]),
    ),
    MockTrack(
      id: '6',
      title: 'Deep Space',
      artist: 'Cosmic Mind',
      durationStr: '4:20',
      totalDurationSeconds: 260.0,
      coverGradient: const LinearGradient(colors: [Color(0xFF72008D), Color(0xFF000000)]),
    ),
    MockTrack(
      id: '7',
      title: 'Acoustic Sun',
      artist: 'Guitar Hero',
      durationStr: '2:55',
      totalDurationSeconds: 175.0,
      coverGradient: const LinearGradient(colors: [Color(0xFFFF2D85), Color(0xFFFFCC00)]),
    ),
    MockTrack(
      id: '8',
      title: 'Retro Dream',
      artist: '80s Fever',
      durationStr: '3:33',
      totalDurationSeconds: 213.0,
      coverGradient: const LinearGradient(colors: [Color(0xFF5AC8FA), Color(0xFFC358D7)]),
    ),
  ];

  late List<MockTrack> _filteredTracks;
  MockTrack? _selectedTrack;
  String? _previewingTrackId;

  // Trimmer state
  int _selectedDurationSeconds = 15;
  double _trimStartPercent = 0.2; // 0.0 to 1.0

  @override
  void initState() {
    super.initState();
    _filteredTracks = List.from(_allTracks);

    // If editing, load initial state
    final initialSticker = widget.initialSticker;
    if (initialSticker != null && initialSticker.isMusic) {
      final matchedTrack = _allTracks.firstWhere(
        (t) => t.title == initialSticker.musicTitle,
        orElse: () => _allTracks.first,
      );
      _selectedTrack = matchedTrack;
      _selectedDurationSeconds = (initialSticker.musicTrimDuration ?? 15.0).toInt();
      final totalSec = matchedTrack.totalDurationSeconds;
      final startSec = initialSticker.musicTrimStart ?? 0.0;
      _trimStartPercent = (startSec / totalSec).clamp(0.0, 1.0);
    }
  }

  void _onSearch(String value) {
    setState(() {
      _filteredTracks = _allTracks
          .where((track) =>
              track.title.toLowerCase().contains(value.toLowerCase()) ||
              track.artist.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  void _onDone() {
    if (_selectedTrack == null) return;

    final startSec = _trimStartPercent * _selectedTrack!.totalDurationSeconds;

    final result = (widget.initialSticker ?? StickerData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '🎵 ${_selectedTrack!.title}',
      position: const Offset(100, 200),
    )).copyWith(
      isMusic: true,
      musicTitle: _selectedTrack!.title,
      musicArtist: _selectedTrack!.artist,
      musicTrimStart: startSec,
      musicTrimDuration: _selectedDurationSeconds.toDouble(),
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Indicator handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_selectedTrack != null && widget.initialSticker == null) {
                      setState(() {
                        _selectedTrack = null;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    (_selectedTrack != null && widget.initialSticker == null) ? 'Back' : 'Cancel',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _selectedTrack != null ? 'Trim Music' : 'Select Music',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                _selectedTrack != null
                    ? GestureDetector(
                        onTap: _onDone,
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Color(0xFFC358D7),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox(width: 48),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: _selectedTrack != null ? _buildTrimmerView() : _buildSelectionView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionView() {
    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: _onSearch,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search music or artists...',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            itemCount: _filteredTracks.length,
            itemBuilder: (context, index) {
              final track = _filteredTracks[index];
              final isPlaying = _previewingTrackId == track.id;

              return ListTile(
                onTap: () {
                  setState(() {
                    _selectedTrack = track;
                  });
                },
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: track.coverGradient,
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note, color: Colors.white, size: 20),
                  ),
                ),
                title: Text(
                  track.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  track.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.durationStr,
                      style: const TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: isPlaying ? const Color(0xFFC358D7) : Colors.white70,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isPlaying) {
                            _previewingTrackId = null;
                          } else {
                            _previewingTrackId = track.id;
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrimmerView() {
    final track = _selectedTrack!;
    final totalSec = track.totalDurationSeconds;
    final startSec = _trimStartPercent * totalSec;
    final endSec = min(startSec + _selectedDurationSeconds, totalSec);

    // Format helpers
    String formatTime(double seconds) {
      final m = seconds ~/ 60;
      final s = (seconds % 60).toInt();
      return '$m:${s.toString().padLeft(2, '0')}';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Track Info Card
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: track.coverGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Center(
                child: Icon(Icons.music_note, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              track.title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              track.artist,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Duration selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [5, 10, 15, 30].map((duration) {
                final isSel = _selectedDurationSeconds == duration;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDurationSeconds = duration;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFC358D7) : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSel ? Colors.white24 : Colors.transparent),
                    ),
                    child: Text(
                      '${duration}s',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Segment Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start: ${formatTime(startSec)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  'End: ${formatTime(endSec)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Custom Waveform Slider
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                final box = context.findRenderObject() as RenderBox;
                final screenWidth = box.size.width - 48; // padding adjusted
                final deltaPercent = details.primaryDelta! / screenWidth;
                setState(() {
                  _trimStartPercent = (_trimStartPercent + deltaPercent).clamp(0.0, 1.0 - (_selectedDurationSeconds / totalSec));
                });
              },
              child: Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 1),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // Segment highlight math
                    final highlightLeft = _trimStartPercent * width;
                    final highlightWidth = (_selectedDurationSeconds / totalSec) * width;

                    return Stack(
                      children: [
                        // Waveform background lines
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(32, (index) {
                                // Deterministic random heights
                                final h = 10.0 + (sin(index * 0.8) + 1) * 16;
                                return Container(
                                  width: 4,
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                        // Sliding Active Window Box
                        Positioned(
                          left: highlightLeft,
                          top: 2,
                          bottom: 2,
                          width: max(highlightWidth, 30.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFC358D7).withValues(alpha: 0.25),
                              border: Border.all(color: const Color(0xFFC358D7), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Drag the highlight box to trim the song segment',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

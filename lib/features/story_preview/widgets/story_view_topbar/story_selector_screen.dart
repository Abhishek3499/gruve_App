import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/highlights_create/controller/highlight_create_controller.dart';
import 'package:provider/provider.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

class StorySelectorScreen extends StatefulWidget {
  final List<String> mediaPaths;

  const StorySelectorScreen({super.key, required this.mediaPaths});

  @override
  State<StorySelectorScreen> createState() => _StorySelectorScreenState();
}

class _StorySelectorScreenState extends State<StorySelectorScreen> {
  int selectedIndex = -1;

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Select Story',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: selectedIndex != -1
                ? () {
                    Navigator.pop(context, widget.mediaPaths[selectedIndex]);
                  }
                : null,
            child: const Text(
              'Next',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: widget.mediaPaths.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(widget.mediaPaths[index]),
                if (isSelected)
                  Container(
                    color: Colors.black26,
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CreateHighlightSheet extends StatefulWidget {
  final String storyImageUrl;
  final String storyId;

  const CreateHighlightSheet({
    super.key,
    required this.storyImageUrl,
    required this.storyId,
  });

  @override
  State<CreateHighlightSheet> createState() => _CreateHighlightSheetState();
}

class _CreateHighlightSheetState extends State<CreateHighlightSheet> {
  final TextEditingController _nameController = TextEditingController();
  late final HighlightCreateController _createController;

  @override
  void initState() {
    super.initState();
    _createController = context.read<HighlightCreateController>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Highlight',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Image with small preview size
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 170,
                width: 110,
                child: _buildImage(widget.storyImageUrl),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _nameController,

              maxLines: 1,
              style: const TextStyle(
                color: Colors.black, // typed text color
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter Highlights',
                hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 59, 59, 59),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,

                prefixIcon: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.grey,
                ),

                // IMPORTANT
                isDense: true,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.3),
                ),

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () async {
                AppLogger.d("➕ New highlight submit → API CALL START");

                // ✅ Validate title
                if (_nameController.text.trim().isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a highlight name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // ✅ USE DIRECTLY PASSED STORY ID (IMPORTANT FIX)
                final storyId = widget.storyId;

                AppLogger.d("🧪 [DEBUG] FIXED Story ID: $storyId");
                AppLogger.d(
                  "🧪 [DEBUG] Story Image URL: ${widget.storyImageUrl}",
                );

                // ❌ prevent null / empty
                if (storyId.isEmpty) {
                  AppLogger.d("❌ ERROR: Story ID is empty");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Story ID not found. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // ❌ prevent wrong format
                if (storyId.endsWith('.jpg') ||
                    storyId.endsWith('.png') ||
                    storyId.endsWith('.mp4')) {
                  AppLogger.d("❌ ERROR: Wrong storyId (image file detected)");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid story ID format.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // 🚀 API CALL
                await _createController.addStoryToHighlight(
                  highlightId: null,
                  storyId: storyId,
                  title: _nameController.text.trim(),
                );

                // ✅ Success handling
                if (_createController.isSuccess) {
                  AppLogger.d("✅ Highlight created successfully");

                  if (!mounted) return;

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Highlight created successfully! 🎉'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  AppLogger.d("❌ Highlight creation failed");
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Add"),
            ),
          ),
        ],
      ),
    );
  }
}

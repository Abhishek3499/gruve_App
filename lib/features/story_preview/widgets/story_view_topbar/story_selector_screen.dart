import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/story_preview/api/story_api/controller/story_state_controller.dart';

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
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      });
    } else {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      });
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

  const CreateHighlightSheet({super.key, required this.storyImageUrl});

  @override
  State<CreateHighlightSheet> createState() => _CreateHighlightSheetState();
}

class _CreateHighlightSheetState extends State<CreateHighlightSheet> {
  final TextEditingController _nameController = TextEditingController();

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      });
    } else {
      return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      });
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
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
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Highlights',
                filled: true,
                fillColor: Colors.grey[100],
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const Spacer(),

          // Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
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

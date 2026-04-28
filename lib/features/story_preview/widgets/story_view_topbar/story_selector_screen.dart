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
                Image.network(widget.mediaPaths[index], fit: BoxFit.cover),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const Text(
            'New Highlight',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          const SizedBox(height: 20),

          // Image with small preview size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 170,
                  width: 110,
                  child: Image.network(
                    widget.storyImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Highlights'),
            ),
          ),

          const SizedBox(height: 20),

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

import 'package:flutter/material.dart';
import '../models/idea_item.dart';
import '../widgets/ideas_column.dart';

class IdeasScreen extends StatelessWidget {
  const IdeasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Curated Unsplash images for a premium high-aesthetic look matching the screenshot
    final trendingItems = [
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.8,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1542044896530-05d85be9b11a?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.55,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.75,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.8,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1542044896530-05d85be9b11a?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.55,
      ),
    ];

    final songsItems = [
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500&auto=format&fit=crop&q=80',
        label: '2021 January Story',
        aspectRatio: 0.65,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 1.25,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500&auto=format&fit=crop&q=80',
        label: '2021 January Story',
        aspectRatio: 0.65,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=500&auto=format&fit=crop&q=80',
        label: '2021 January Story',
        aspectRatio: 0.65,
      ),
    ];

    final actingItems = [
      const IdeaItem(solidColor: Colors.black, aspectRatio: 1.0),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1563089145-599997674d42?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.65,
      ),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.75,
      ),
      const IdeaItem(solidColor: Colors.black, aspectRatio: 1.0),
      const IdeaItem(
        imageUrl:
            'https://images.unsplash.com/photo-1563089145-599997674d42?w=500&auto=format&fit=crop&q=80',
        aspectRatio: 0.65,
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF42174C), // Deep plum purple
              Color(0xFF9544A7), // Light magenta/purple
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header Bar with Back Button
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                // Wrap in Material to support ink ripples on the back button
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Back',
                  ),
                ),
              ),

              // Sticky Tabs Bar (Aligned with columns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Trending Tab Header
                  Expanded(
                    flex: 28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: const BoxDecoration(
                        // color: Color(0xFF23032B), // Very dark purple/black tab background
                        borderRadius: BorderRadius.only(
                          // topLeft: Radius.circular(20),
                          // topRight: Radius.circular(20), // rounded top-right for tab shape
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            'Trending',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Songs & Acting Container Tab Header
                  Expanded(
                    flex: 72,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(
                          0xFF5C1B6D,
                        ), // Matches the card container background
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: const Text(
                                  'Songs',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: const Text(
                                  'Acting',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Scrollable card columns layout below the Sticky tabs
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        // IntrinsicHeight ensures the container stretches to match height
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Column 1: Trending cards (Outside Container, Dark background)
                              Expanded(
                                flex: 28,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    12,
                                    4,
                                    24,
                                  ),
                                  child: IdeasColumn(items: trendingItems),
                                ),
                              ),

                              // Column 2 & 3: Songs & Acting cards (Enclosed in Purple Container)
                              Expanded(
                                flex: 72,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(
                                      0xFF5C1B6D,
                                    ), // Solid deep purple card background
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    12,
                                    8,
                                    24,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Column 2: Songs
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: IdeasColumn(items: songsItems),
                                        ),
                                      ),

                                      // Column 3: Acting
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: IdeasColumn(
                                            items: actingItems,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

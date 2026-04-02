import 'package:flutter/material.dart';
import 'package:gruve_app/features/profile_menu_drawer/constants/post/more_constants.dart';
import 'package:gruve_app/features/profile_menu_drawer/models/post/more_model.dart';
import 'package:gruve_app/features/story_preview/widgets/more_widgets/more_card.dart';
import 'package:gruve_app/features/story_preview/widgets/more_widgets/more_header.dart';
import 'package:gruve_app/features/story_preview/widgets/more_widgets/more_toggle.dart';

class MoreOptionScreen extends StatefulWidget {
  const MoreOptionScreen({super.key});

  @override
  State<MoreOptionScreen> createState() => _MoreOptionScreenState();
}

class _MoreOptionScreenState extends State<MoreOptionScreen> {
  // Logic to handle toggle states separately for each section
  // _MoreOptionScreenState ke andar
  Map<String, List<bool>> sectionStates = {};

  @override
  void initState() {
    super.initState();

    // Pehle check karo data hai bhi ya nahi
    if (MoreConstants.sections.isNotEmpty) {
      MoreConstants.sections.forEach((key, list) {
        // List.from use karo taaki original data modify na ho
        sectionStates[key] = list.map((e) => e.isEnabled).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient:
              MoreConstants.backgroundGradient, // Use your constant gradient
        ),
        child: SafeArea(
          child: Column(
            children: [
              MoreHeader(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 10),

              // Scrollable area for cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: MoreConstants.sections.entries.map((entry) {
                      String sectionTitle = entry.key;
                      List<MoreModel> options = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION HEADER TEXT
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Text(
                              sectionTitle,
                              style: MoreConstants.sectionTitleStyle,
                            ),
                          ),

                          // THE CARD
                          MoreCard(
                            child: Column(
                              children: options.asMap().entries.map((
                                optionEntry,
                              ) {
                                int idx = optionEntry.key;
                                var option = optionEntry.value;

                                return MoreToggle(
                                  title: option.title,
                                  description: option.description,
                                  icon: option.icon, // Pass the icon path here
                                  value: sectionStates[sectionTitle]![idx],
                                  onChanged: (val) {
                                    setState(() {
                                      sectionStates[sectionTitle]![idx] = val;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

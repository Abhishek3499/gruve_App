import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/activity_controller.dart';
import 'custom_activity_chart.dart';

class ActivityInsightsCard extends StatefulWidget {
  final ActivityController controller;

  const ActivityInsightsCard({super.key, required this.controller});

  @override
  State<ActivityInsightsCard> createState() => _ActivityInsightsCardState();
}

class _ActivityInsightsCardState extends State<ActivityInsightsCard> {
  FilterType _selected = FilterType.weekly;

  void _showFilterMenu(BuildContext context) {
    final filters = FilterType.values;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: filters.map((f) {
              final label = f.name[0].toUpperCase() + f.name.substring(1);
              return ListTile(
                title: Text(
                  label,
                  style: TextStyle(
                    color: _selected == f
                        ? const Color(0xFF00E5FF)
                        : Colors.white,
                    fontWeight: _selected == f
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _selected == f
                    ? const Icon(Icons.check, color: Color(0xFF00E5FF))
                    : null,
                onTap: () {
                  setState(() => _selected = f);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String get _filterLabel {
    switch (_selected) {
      case FilterType.weekly:
        return 'Weekly';
      case FilterType.monthly:
        return 'Monthly';
      case FilterType.yearly:
        return 'Yearly';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A2E), // Deep purple-dark background
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B46C1).withOpacity(0.3), // Purple glow
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterMenu(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _filterLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: CustomActivityChart(
                    controller: widget.controller,
                    filterType: _selected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

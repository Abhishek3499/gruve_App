import 'package:flutter/material.dart';
import 'package:gruve_app/features/camera/domain/entities/filter_model.dart';

class StoryFilterPicker extends StatefulWidget {
  final FilterModel initialFilter;
  final ValueChanged<FilterModel> onFilterChanged;

  const StoryFilterPicker({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
  });

  static Future<void> open(
    BuildContext context, {
    required FilterModel initialFilter,
    required ValueChanged<FilterModel> onFilterChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StoryFilterPicker(
          initialFilter: initialFilter,
          onFilterChanged: onFilterChanged,
        );
      },
    );
  }

  @override
  State<StoryFilterPicker> createState() => _StoryFilterPickerState();
}

class _StoryFilterPickerState extends State<StoryFilterPicker> {
  late FilterModel _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Color(0xEB161616),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle drag bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48),
                const Text(
                  'Select Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFFC358D7),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: FilterModel.availableFilters.length,
              itemBuilder: (context, index) {
                final filter = FilterModel.availableFilters[index];
                final isSelected = filter.type == _selectedFilter.type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    widget.onFilterChanged(filter);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.scale(
                          scale: isSelected ? 1.15 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white24,
                                width: isSelected ? 3 : 1.5,
                              ),
                              color: isSelected
                                  ? _getFilterColor(filter.type).withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                            child: Icon(
                              filter.icon,
                              color: isSelected ? Colors.white : Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          filter.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum FilterType {
  none,
  warm,
  cool,
  sepia,
  vintage,
  blackAndWhite,
  vivid,
  dramatic,
}

class FilterModel {
  final FilterType type;
  final String name;
  final List<double> matrix;
  final IconData icon;

  const FilterModel({
    required this.type,
    required this.name,
    required this.matrix,
    required this.icon,
  });

  static const List<FilterModel> availableFilters = [
    FilterModel(
      type: FilterType.none,
      name: 'Normal',
      matrix: [],
      icon: Icons.photo_camera,
    ),
    FilterModel(
      type: FilterType.warm,
      name: 'Warm',
      matrix: [
        1.2, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.1, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.8, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.wb_sunny,
    ),
    FilterModel(
      type: FilterType.cool,
      name: 'Cool',
      matrix: [
        0.8, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.3, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.ac_unit,
    ),
    FilterModel(
      type: FilterType.sepia,
      name: 'Sepia',
      matrix: [
        0.393, 0.769, 0.189, 0.0, 0.0,
        0.349, 0.686, 0.168, 0.0, 0.0,
        0.272, 0.534, 0.131, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.filter_vintage,
    ),
    FilterModel(
      type: FilterType.vintage,
      name: 'Vintage',
      matrix: [
        0.6, 0.3, 0.1, 0.0, 0.0,
        0.2, 0.7, 0.1, 0.0, 0.0,
        0.1, 0.1, 0.8, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.history,
    ),
    FilterModel(
      type: FilterType.blackAndWhite,
      name: 'B&W',
      matrix: [
        0.299, 0.587, 0.114, 0.0, 0.0,
        0.299, 0.587, 0.114, 0.0, 0.0,
        0.299, 0.587, 0.114, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.contrast,
    ),
    FilterModel(
      type: FilterType.vivid,
      name: 'Vivid',
      matrix: [
        1.5, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.5, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.5, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.vibration,
    ),
    FilterModel(
      type: FilterType.dramatic,
      name: 'Dramatic',
      matrix: [
        1.2, 0.0, 0.0, 0.0, -0.1,
        0.0, 1.1, 0.0, 0.0, -0.05,
        0.0, 0.0, 1.3, 0.0, -0.1,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.theater_comedy,
    ),
  ];

  static FilterModel getFilterByType(FilterType type) {
    return availableFilters.firstWhere(
      (filter) => filter.type == type,
      orElse: () => availableFilters.first,
    );
  }

  bool get hasMatrix => matrix.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterModel && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}

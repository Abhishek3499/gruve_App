import 'package:flutter/material.dart';

enum FilterType {
  none,
  clarendon,
  gingham,
  moon,
  lark,
  reyes,
  juno,
  slumber,
  crema,
  ludwig,
  aden,
  perpetua,
  mayfair,
  rise,
  hudson,
  valencia,
  xpro2,
  sepia,
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
      type: FilterType.clarendon,
      name: 'Clarendon',
      matrix: [
        1.3, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.2, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.4, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.brightness_high,
    ),
    FilterModel(
      type: FilterType.gingham,
      name: 'Gingham',
      matrix: [
        1.1, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.grain,
    ),
    FilterModel(
      type: FilterType.moon,
      name: 'Moon',
      matrix: [
        0.8, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.7, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.nights_stay,
    ),
    FilterModel(
      type: FilterType.lark,
      name: 'Lark',
      matrix: [
        1.2, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.1, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.8, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.wb_cloudy,
    ),
    FilterModel(
      type: FilterType.reyes,
      name: 'Reyes',
      matrix: [
        0.9, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.9, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.1, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.filter_drama,
    ),
    FilterModel(
      type: FilterType.juno,
      name: 'Juno',
      matrix: [
        1.1, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.2, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.flash_on,
    ),
    FilterModel(
      type: FilterType.slumber,
      name: 'Slumber',
      matrix: [
        0.8, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.8, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.bedtime,
    ),
    FilterModel(
      type: FilterType.crema,
      name: 'Crema',
      matrix: [
        1.1, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.local_cafe,
    ),
    FilterModel(
      type: FilterType.ludwig,
      name: 'Ludwig',
      matrix: [
        1.2, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.1, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.music_note,
    ),
    FilterModel(
      type: FilterType.aden,
      name: 'Aden',
      matrix: [
        0.9, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.9, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.blur_on,
    ),
    FilterModel(
      type: FilterType.perpetua,
      name: 'Perpetua',
      matrix: [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.1, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.landscape,
    ),
    FilterModel(
      type: FilterType.mayfair,
      name: 'Mayfair',
      matrix: [
        1.3, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.1, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.wb_sunny,
    ),
    FilterModel(
      type: FilterType.rise,
      name: 'Rise',
      matrix: [
        1.1, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.8, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.filter_vintage,
    ),
    FilterModel(
      type: FilterType.hudson,
      name: 'Hudson',
      matrix: [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.2, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.cloud,
    ),
    FilterModel(
      type: FilterType.valencia,
      name: 'Valencia',
      matrix: [
        1.1, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.9, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.9, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.vignette,
    ),
    FilterModel(
      type: FilterType.xpro2,
      name: 'X-Pro II',
      matrix: [
        1.3, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.1, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.8, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ],
      icon: Icons.camera_alt,
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

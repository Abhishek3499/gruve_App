import 'package:flutter/foundation.dart';
import '../models/filter_model.dart';

class FilterController extends ChangeNotifier {
  static final FilterController _instance = FilterController._internal();
  factory FilterController() => _instance;
  FilterController._internal();

  FilterModel _selectedFilter = FilterModel.availableFilters.first;
  bool _faceFilterEnabled = false;

  FilterModel get selectedFilter => _selectedFilter;
  bool get faceFilterEnabled => _faceFilterEnabled;

  void setFilter(FilterModel filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  void setFilterByType(FilterType type) {
    final filter = FilterModel.getFilterByType(type);
    setFilter(filter);
  }

  void toggleFaceFilter() {
    _faceFilterEnabled = !_faceFilterEnabled;
    notifyListeners();
  }

  void setFaceFilterEnabled(bool enabled) {
    if (_faceFilterEnabled != enabled) {
      _faceFilterEnabled = enabled;
      notifyListeners();
    }
  }

  void reset() {
    _selectedFilter = FilterModel.availableFilters.first;
    _faceFilterEnabled = false;
    notifyListeners();
  }

  bool get hasActiveFilter => _selectedFilter.type != FilterType.none || _faceFilterEnabled;
}

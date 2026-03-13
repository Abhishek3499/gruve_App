import 'package:flutter/material.dart';
import '../models/activity_model.dart';

enum FilterType { weekly, monthly, yearly }

class ActivityController extends ChangeNotifier {
  ActivityModel _activityModel = const ActivityModel(
    totalTime: '9h 12m',
    description:
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
    weeklyData: [
      ActivityData(day: 'Sun', hours: 3.2, time: '3h 12m'),
      ActivityData(day: 'Mon', hours: 4.5, time: '4h 30m'),
      ActivityData(day: 'Tue', hours: 4.0, time: '4h 00m'),
      ActivityData(day: 'Wed', hours: 6.0, time: '6h 00m'),
      ActivityData(day: 'Thu', hours: 9.2, time: '9h 12m'),
      ActivityData(day: 'Fri', hours: 5.5, time: '5h 30m'),
      ActivityData(day: 'Sat', hours: 5.8, time: '5h 48m'),
    ],
    monthlyData: [
      ActivityData(day: 'Jan', hours: 5.0, time: '5h 00m'),
      ActivityData(day: 'Feb', hours: 6.2, time: '6h 12m'),
      ActivityData(day: 'Mar', hours: 7.5, time: '7h 30m'),
      ActivityData(day: 'Apr', hours: 4.8, time: '4h 48m'),
      ActivityData(day: 'May', hours: 8.0, time: '8h 00m'),
      ActivityData(day: 'Jun', hours: 6.5, time: '6h 30m'),
      ActivityData(day: 'Jul', hours: 9.0, time: '9h 00m'),
      ActivityData(day: 'Aug', hours: 7.2, time: '7h 12m'),
      ActivityData(day: 'Sep', hours: 5.5, time: '5h 30m'),
      ActivityData(day: 'Oct', hours: 6.8, time: '6h 48m'),
      ActivityData(day: 'Nov', hours: 8.5, time: '8h 30m'),
      ActivityData(day: 'Dec', hours: 7.0, time: '7h 00m'),
    ],
    yearlyData: [
      ActivityData(day: '2019', hours: 4.5, time: '4h 30m'),
      ActivityData(day: '2020', hours: 5.8, time: '5h 48m'),
      ActivityData(day: '2021', hours: 6.2, time: '6h 12m'),
      ActivityData(day: '2022', hours: 7.0, time: '7h 00m'),
      ActivityData(day: '2023', hours: 8.5, time: '8h 30m'),
      ActivityData(day: '2024', hours: 9.2, time: '9h 12m'),
      ActivityData(day: '2025', hours: 7.8, time: '7h 48m'),
    ],
    selectedPeriod: 'Weekly',
  );

  ActivityModel get activityModel => _activityModel;

  void updatePeriod(String period) {
    debugPrint("[ActivityController] Period updated to: $period");
    _activityModel = _activityModel.copyWith(selectedPeriod: period);
    notifyListeners();
  }

  List<ActivityData> getDataFor(FilterType type) {
    switch (type) {
      case FilterType.weekly:
        return _activityModel.weeklyData;
      case FilterType.monthly:
        return _activityModel.monthlyData;
      case FilterType.yearly:
        return _activityModel.yearlyData;
    }
  }

  List<ActivityData> get weeklyData => _activityModel.weeklyData;
  List<ActivityData> get monthlyData => _activityModel.monthlyData;
  List<ActivityData> get yearlyData => _activityModel.yearlyData;
  String get totalTime => _activityModel.totalTime;
  String get description => _activityModel.description;
  String get selectedPeriod => _activityModel.selectedPeriod;
}

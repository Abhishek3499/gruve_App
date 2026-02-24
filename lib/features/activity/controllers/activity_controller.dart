import 'package:flutter/material.dart';
import '../models/activity_model.dart';

class ActivityController extends ChangeNotifier {
  ActivityModel _activityModel = const ActivityModel(
    totalTime: '9h 12m',
    description:
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
    weeklyData: [
      ActivityData(day: 'Sun', hours: 7.5, time: '7h 30m'),
      ActivityData(day: 'Mon', hours: 8.2, time: '8h 12m'),
      ActivityData(day: 'Tue', hours: 9.2, time: '9h 12m'),
      ActivityData(day: 'Wed', hours: 6.8, time: '6h 48m'),
      ActivityData(day: 'Thu', hours: 8.5, time: '8h 30m'),
      ActivityData(day: 'Fri', hours: 7.2, time: '7h 12m'),
      ActivityData(day: 'Sat', hours: 5.5, time: '5h 30m'),
    ],
    selectedPeriod: 'Weekly',
  );

  ActivityModel get activityModel => _activityModel;

  void updatePeriod(String period) {
    debugPrint("[ActivityController] Period updated to: $period");
    _activityModel = _activityModel.copyWith(selectedPeriod: period);
    notifyListeners();
  }

  List<ActivityData> get weeklyData => _activityModel.weeklyData;
  String get totalTime => _activityModel.totalTime;
  String get description => _activityModel.description;
  String get selectedPeriod => _activityModel.selectedPeriod;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gruve_app/features/analytics/activity/domain/entities/activity_model.dart';
import 'package:gruve_app/core/utils/app_logger.dart';

enum FilterType { weekly, monthly, yearly }

class ActivityController extends Notifier<ActivityModel> {
  static const ActivityModel _initialActivityModel = ActivityModel(
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

  @override
  ActivityModel build() => _initialActivityModel;

  ActivityModel get activityModel => state;

  void updatePeriod(String period) {
    AppLogger.d("[ActivityController] Period updated to: $period");
    state = state.copyWith(selectedPeriod: period);
  }

  List<ActivityData> getDataFor(FilterType type) {
    switch (type) {
      case FilterType.weekly:
        return state.weeklyData;
      case FilterType.monthly:
        return state.monthlyData;
      case FilterType.yearly:
        return state.yearlyData;
    }
  }

  List<ActivityData> get weeklyData => state.weeklyData;
  List<ActivityData> get monthlyData => state.monthlyData;
  List<ActivityData> get yearlyData => state.yearlyData;
  String get totalTime => state.totalTime;
  String get description => state.description;
  String get selectedPeriod => state.selectedPeriod;
}

final activityControllerProvider =
    NotifierProvider<ActivityController, ActivityModel>(ActivityController.new);

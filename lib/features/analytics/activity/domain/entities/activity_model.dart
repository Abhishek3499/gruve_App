class ActivityModel {
  final String totalTime;
  final String description;
  final List<ActivityData> weeklyData;
  final List<ActivityData> monthlyData;
  final List<ActivityData> yearlyData;
  final String selectedPeriod;

  const ActivityModel({
    required this.totalTime,
    required this.description,
    required this.weeklyData,
    required this.monthlyData,
    required this.yearlyData,
    required this.selectedPeriod,
  });

  ActivityModel copyWith({
    String? totalTime,
    String? description,
    List<ActivityData>? weeklyData,
    List<ActivityData>? monthlyData,
    List<ActivityData>? yearlyData,
    String? selectedPeriod,
  }) {
    return ActivityModel(
      totalTime: totalTime ?? this.totalTime,
      description: description ?? this.description,
      weeklyData: weeklyData ?? this.weeklyData,
      monthlyData: monthlyData ?? this.monthlyData,
      yearlyData: yearlyData ?? this.yearlyData,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

class ActivityData {
  final String day;
  final double hours;
  final String time;

  const ActivityData({
    required this.day,
    required this.hours,
    required this.time,
  });
}

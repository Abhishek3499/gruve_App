class ActivityModel {
  final String totalTime;
  final String description;
  final List<ActivityData> weeklyData;
  final String selectedPeriod;

  const ActivityModel({
    required this.totalTime,
    required this.description,
    required this.weeklyData,
    required this.selectedPeriod,
  });

  ActivityModel copyWith({
    String? totalTime,
    String? description,
    List<ActivityData>? weeklyData,
    String? selectedPeriod,
  }) {
    return ActivityModel(
      totalTime: totalTime ?? this.totalTime,
      description: description ?? this.description,
      weeklyData: weeklyData ?? this.weeklyData,
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

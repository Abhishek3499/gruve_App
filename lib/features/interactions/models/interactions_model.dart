/// Interactions data model
class InteractionsModel {
  final String totalInteractions;
  final String followersCount;
  final String nonFollowersCount;
  final String growthPercentage;
  final double followersPercentage;
  final double nonFollowersPercentage;
  final List<ContentTypeData> contentTypes;

  const InteractionsModel({
    required this.totalInteractions,
    required this.followersCount,
    required this.nonFollowersCount,
    required this.growthPercentage,
    required this.followersPercentage,
    required this.nonFollowersPercentage,
    required this.contentTypes,
  });

  static const InteractionsModel data = InteractionsModel(
    totalInteractions: '2,409',
    followersCount: '39.8%',
    nonFollowersCount: '60.2%',
    growthPercentage: '+71.5%',
    followersPercentage: 39.8,
    nonFollowersPercentage: 60.2,
    contentTypes: [
      ContentTypeData(label: 'Videos', percentage: 89.2),
      ContentTypeData(label: 'Stories', percentage: 39.2),
    ],
  );
}

/// Content type data model
class ContentTypeData {
  final String label;
  final double percentage;

  const ContentTypeData({required this.label, required this.percentage});
}

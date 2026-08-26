class SubscriptionCardModel {
  final String iconPath;
  final int coins;
  final String price;
  final bool isSelected;
  final bool isLocked;

  const SubscriptionCardModel({
    required this.iconPath,
    required this.coins,
    required this.price,
    this.isSelected = false,
    this.isLocked = false,
  });
}

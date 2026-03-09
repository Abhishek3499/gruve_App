class CloseFrindUserModel {
  final String name;
  final String handle;
  bool isSelected;

  CloseFrindUserModel({
    required this.name,
    required this.handle,
    this.isSelected = false,
  });
}

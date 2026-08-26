class MoreModel {
  final String title;
  final String description;
  final bool isEnabled; // Isko default true/false rakho constants mein
  final String icon;

  const MoreModel({
    required this.title,
    required this.description,
    this.isEnabled = false, // Default value add kardi
    required this.icon,
  });
}

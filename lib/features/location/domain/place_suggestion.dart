class PlaceSuggestion {
  final String title;
  final String? subtitle;
  final String formatted;

  const PlaceSuggestion({
    required this.title,
    required this.formatted,
    this.subtitle,
  });

  factory PlaceSuggestion.fromGeoapify(Map<String, dynamic> props) {
    final formatted = (props['formatted'] ?? '').toString();
    final name = props['name']?.toString();
    final title = (name != null && name.isNotEmpty)
        ? name
        : (props['address_line1'] ?? formatted).toString();
    final subtitle = props['address_line2']?.toString();
    return PlaceSuggestion(
      title: title,
      subtitle: (subtitle == null || subtitle.isEmpty) ? null : subtitle,
      formatted: formatted,
    );
  }
}

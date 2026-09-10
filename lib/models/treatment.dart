class Treatment {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> steps;
  final bool isOrganic;
  final String? icon;

  const Treatment({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.steps,
    required this.isOrganic,
    this.icon,
  });
}
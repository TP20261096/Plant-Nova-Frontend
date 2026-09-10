class Activity {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String type;
  final DateTime date;
  final bool isCompleted;
  final List<String> plantsInvolved;

  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.date,
    this.isCompleted = false,
    this.plantsInvolved = const [],
  });
}
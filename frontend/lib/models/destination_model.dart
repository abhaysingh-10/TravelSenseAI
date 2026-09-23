class Destination {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double matchScore;
  final String reason;
  
  final double estimatedBudget;
  final int durationDays;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.matchScore,
    required this.reason,
    this.estimatedBudget = 15000.0,
    this.durationDays = 5,
  });
}

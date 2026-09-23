class Destination {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double matchScore; 
  final String reason; 

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.matchScore,
    required this.reason,
  });
}

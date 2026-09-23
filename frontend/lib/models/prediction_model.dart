class TripPrediction {
  final double estimatedCost;
  final int estimatedDurationDays;
  final double confidenceScore; // 0.0 to 1.0

  TripPrediction({
    required this.estimatedCost,
    required this.estimatedDurationDays,
    required this.confidenceScore,
  });
}

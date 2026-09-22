class Trip {
  final String id;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final double spent;
  final String imageUrl;
  final int weatherTemp;

  Trip({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.spent,
    required this.imageUrl,
    required this.weatherTemp,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      destination: json['destination'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      budget: (json['budget'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      imageUrl: json['image_url'],
      weatherTemp: json['weather_temp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'budget': budget,
      'spent': spent,
      'image_url': imageUrl,
      'weather_temp': weatherTemp,
    };
  }

  Trip copyWith({
    String? id,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    double? spent,
    String? imageUrl,
    int? weatherTemp,
  }) {
    return Trip(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      spent: spent ?? this.spent,
      imageUrl: imageUrl ?? this.imageUrl,
      weatherTemp: weatherTemp ?? this.weatherTemp,
    );
  }
}

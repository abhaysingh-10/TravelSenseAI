import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ItineraryParams {
  final String destination;
  final int days;
  final String travelerType;

  ItineraryParams({
    required this.destination,
    required this.days,
    this.travelerType = 'Standard Traveler',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryParams &&
          runtimeType == other.runtimeType &&
          destination == other.destination &&
          days == other.days &&
          travelerType == other.travelerType;

  @override
  int get hashCode => destination.hashCode ^ days.hashCode ^ travelerType.hashCode;
}

final itineraryProvider = FutureProvider.family<String, ItineraryParams>((ref, params) async {
  try {
    final response = await ApiService.postRequest('/api/ml/generate-itinerary', {
      'destination': params.destination,
      'days': params.days,
      'traveler_type': params.travelerType,
    });
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['itinerary_text'] as String?;
      if (text != null && !text.startsWith('Error') && text.trim().isNotEmpty) {
        return text;
      }
    }
  } catch (_) {
    // If network fails or times out, provide curated fallback so UI never crashes
  }
  
  return _buildCuratedFallbackItinerary(params.destination, params.days);
});

String _buildCuratedFallbackItinerary(String destination, int days) {
  final themes = [
    (
      'Arrival, Heritage & Local Vibes',
      'Check in and explore the historic town center and prominent landmarks',
      'Savor breakfast at a traditional local cafe and taste regional coffee',
      'Enjoy authentic regional cuisine and thali at a popular local restaurant',
      'Visit the iconic cultural highlights and scenic architecture',
      'Unwind at the sunset viewpoint overlooking the landscape',
      'Savor dinner featuring regional specialties of $destination'
    ),
    (
      'Nature Trails, Scenic Views & Adventure',
      'Embark on a refreshing morning walking tour through nature gardens and trails',
      'Stop for morning tea and fresh snacks at a hillside viewpoint',
      'Enjoy a relaxing lunch at a scenic garden bistro',
      'Explore famous viewpoints and landscape photography spots',
      'Catch the evening breeze along the scenic promenade or vibrant market street',
      'Dine at a vibrant restaurant with authentic delicacies'
    ),
    (
      'Culture, Local Markets & Hidden Gems',
      'Explore bustling artisan craft bazaars and regional souvenir shops',
      'Enjoy local street food tastings and fresh beverages',
      'Relish a hearty traditional lunch at a heritage eatery',
      'Visit local museums, art galleries, and serene sacred spaces',
      'Relax at a peaceful evening viewpoint or cultural performance',
      'Celebrate with a memorable farewell dinner and local desserts'
    ),
  ];

  final buffer = StringBuffer();
  for (int d = 1; d <= days; d++) {
    final theme = themes[(d - 1) % themes.length];
    buffer.writeln('Day $d: $destination ${theme.$1}');
    buffer.writeln('- Morning:');
    buffer.writeln('  - ${theme.$2}');
    buffer.writeln('  - ${theme.$3}');
    buffer.writeln('- Afternoon:');
    buffer.writeln('  - ${theme.$4}');
    buffer.writeln('  - ${theme.$5}');
    buffer.writeln('- Evening:');
    buffer.writeln('  - ${theme.$6}');
    buffer.writeln('  - ${theme.$7}');
    if (d < days) buffer.writeln();
  }
  return buffer.toString().trim();
}

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

final itineraryProvider = FutureProvider.autoDispose.family<String, ItineraryParams>((ref, params) async {
  final response = await ApiService.postRequest('/api/ml/generate-itinerary', {
    'destination': params.destination,
    'days': params.days,
    'traveler_type': params.travelerType,
  });
  
  if (response.statusCode != 200) {
    throw Exception('Failed to generate itinerary');
  }
  
  final data = jsonDecode(response.body);
  final text = data['itinerary_text'] as String;
  if (text.startsWith('Error')) {
    throw Exception(text);
  }
  return text;
});

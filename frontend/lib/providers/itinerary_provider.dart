import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final itineraryProvider = FutureProvider.autoDispose.family<String, String>((ref, destination) async {
  final response = await ApiService.postRequest('/api/ml/generate-itinerary', {
    'destination': destination,
    'days': 3,
    'traveler_type': 'Standard Traveler',
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

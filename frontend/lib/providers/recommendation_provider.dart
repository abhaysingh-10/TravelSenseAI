import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/destination_model.dart';
import '../services/api_service.dart';
import 'preferences_provider.dart';

class RecommendationNotifier extends Notifier<List<Destination>> {
  bool _isFetching = false;

  @override
  List<Destination> build() {
    final prefs = ref.watch(preferencesProvider);
    Future.microtask(() => fetchRecommendations(preferences: prefs));
    return _initialFallbacks;
  }

  Future<void> fetchRecommendations({String? travelerType, List<String>? preferences}) async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final activePrefs = preferences ?? ref.read(preferencesProvider);
      final queryParams = <String, String>{
        'top_n': '3',
      };
      if (travelerType != null) {
        queryParams['traveler_type'] = travelerType;
      }
      if (activePrefs != null && activePrefs.isNotEmpty) {
        queryParams['preferences'] = activePrefs.join(',');
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final endpoint = '/api/ml/recommendations?$queryString';

      final response = await ApiService.getRequest(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['recommendations'] as List)
            .map((item) => Destination.fromJson(item))
            .toList();
        if (list.isNotEmpty) {
          state = list;
        }
      }
    } catch (_) {
      // Retain existing state if offline
    } finally {
      _isFetching = false;
    }
  }

  static final List<Destination> _initialFallbacks = [
    Destination(
      id: 'dest_manali',
      name: 'Manali',
      description: 'A high-altitude Himalayan resort town known for snow-capped peaks, scenic valleys, and mountain adventures.',
      imageUrl: 'https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?auto=format&fit=crop&w=800&q=80',
      matchScore: 0.95,
      reason: 'Perfect match for scenic mountain escapes and temperate valleys.',
      estimatedBudget: 24500.0,
      durationDays: 4,
    ),
    Destination(
      id: 'dest_goa',
      name: 'Goa',
      description: 'Famous for its golden sand beaches, vibrant coastal culture, Portuguese architecture, and nightlife.',
      imageUrl: 'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80',
      matchScore: 0.92,
      reason: 'Curated for coastal relaxation, beach sunsets, and leisure vibes.',
      estimatedBudget: 28000.0,
      durationDays: 4,
    ),
    Destination(
      id: 'dest_jaipur',
      name: 'Jaipur',
      description: 'The Pink City of Rajasthan, renowned for its grand royal palaces, majestic forts, and rich heritage.',
      imageUrl: 'https://images.unsplash.com/photo-1477587458883-47145ed94245?auto=format&fit=crop&w=800&q=80',
      matchScore: 0.88,
      reason: 'Recommended for royal architecture, cultural heritage, and vibrant bazaars.',
      estimatedBudget: 22000.0,
      durationDays: 4,
    ),
  ];
}

final recommendationProvider = NotifierProvider<RecommendationNotifier, List<Destination>>(RecommendationNotifier.new);

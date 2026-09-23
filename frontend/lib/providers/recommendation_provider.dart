import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/destination_model.dart';

class RecommendationNotifier extends Notifier<List<Destination>> {
  @override
  List<Destination> build() {

    return [
      Destination(
        id: 'd1',
        name: 'Kyoto, Japan',
        description: 'Famous for its classical Buddhist temples, as well as gardens, imperial palaces, Shinto shrines and traditional wooden houses.',
        imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=800&q=80',
        matchScore: 0.94,
        reason: 'Because you love historical sites and temperate weather.',
      ),
      Destination(
        id: 'd2',
        name: 'Santorini, Greece',
        description: 'A beautiful island in the Aegean Sea, known for its whitewashed, cubiform houses clinging to cliffs above an underwater caldera.',
        imageUrl: 'https://images.pexels.com/photos/161815/santorini-oia-greece-water-161815.jpeg?auto=compress&cs=tinysrgb&w=800',
        matchScore: 0.88,
        reason: 'Based on your high spending on coastal luxury trips.',
      ),
      Destination(
        id: 'd3',
        name: 'Banff, Canada',
        description: 'A resort town and one of Canada\'s most popular tourist destinations, known for its mountainous surroundings and hot springs.',
        imageUrl: 'https://images.pexels.com/photos/417074/pexels-photo-417074.jpeg?auto=compress&cs=tinysrgb&w=800',
        matchScore: 0.79,
        reason: 'A great match for your frequent outdoor activity expenses.',
      ),
    ];
  }
}

final recommendationProvider = NotifierProvider<RecommendationNotifier, List<Destination>>(RecommendationNotifier.new);

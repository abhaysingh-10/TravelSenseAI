import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../services/api_service.dart';

class TripListNotifier extends Notifier<List<Trip>> {
  @override
  List<Trip> build() {
    // Initial state is empty. The UI or some init logic should call fetchTrips().
    // Returning an empty list here to maintain synchronous return type.
    fetchTrips();
    return [];
  }

  Future<void> fetchTrips() async {
    try {
      final response = await ApiService.getRequest('/trips');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // The backend `id` is an int, but frontend expects String. The fromJson in trip_model
        // might need to handle this. Let's make sure it parses properly.
        state = data.map((json) {
          // Convert integer ID to string so fromJson works flawlessly
          json['id'] = json['id'].toString();
          return Trip.fromJson(json);
        }).toList();
      }
    } catch (e) {
      print('Error fetching trips: $e');
    }
  }

  Future<void> addTrip(
      String destination, DateTime startDate, DateTime endDate, double budget) async {
    
    final Map<String, dynamic> body = {
      'destination': destination,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'budget': budget,
      'spent': 0.0,
      'image_url': 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&q=80&w=1000',
      'weather_temp': 25,
    };

    try {
      final response = await ApiService.postRequest('/trips', body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        json['id'] = json['id'].toString();
        final newTrip = Trip.fromJson(json);
        state = [...state, newTrip];
      }
    } catch (e) {
      print('Error adding trip: $e');
    }
  }

  Future<void> updateTrip(Trip updatedTrip) async {
    final Map<String, dynamic> body = {
      'destination': updatedTrip.destination,
      'start_date': updatedTrip.startDate.toIso8601String().split('T')[0],
      'end_date': updatedTrip.endDate.toIso8601String().split('T')[0],
      'budget': updatedTrip.budget,
      'spent': updatedTrip.spent,
      'image_url': updatedTrip.imageUrl,
      'weather_temp': updatedTrip.weatherTemp,
    };

    try {
      final response = await ApiService.putRequest('/trips/${updatedTrip.id}', body);
      if (response.statusCode == 200) {
        state = [
          for (final trip in state)
            if (trip.id == updatedTrip.id) updatedTrip else trip
        ];
      }
    } catch (e) {
      print('Error updating trip: $e');
    }
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      final response = await ApiService.deleteRequest('/trips/$tripId');
      if (response.statusCode == 200) {
        state = state.where((trip) => trip.id != tripId).toList();
      }
    } catch (e) {
      print('Error deleting trip: $e');
    }
  }
}

final tripListProvider =
    NotifierProvider<TripListNotifier, List<Trip>>(TripListNotifier.new);

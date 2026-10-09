import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prediction_model.dart';
import 'dart:convert';
import '../services/api_service.dart';

class PredictorState {
  final bool isLoading;
  final TripPrediction? prediction;
  final String? error;

  PredictorState({
    this.isLoading = false,
    this.prediction,
    this.error,
  });

  PredictorState copyWith({
    bool? isLoading,
    TripPrediction? prediction,
    String? error,
  }) {
    return PredictorState(
      isLoading: isLoading ?? this.isLoading,
      prediction: prediction ?? this.prediction,
      error: error,
    );
  }
}

class PredictorNotifier extends Notifier<PredictorState> {
  @override
  PredictorState build() {
    return PredictorState();
  }

  Future<void> predictTrip(String destination, String style, int travelers) async {
    state = state.copyWith(isLoading: true, error: null, prediction: null);

    if (destination.trim().isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter a destination');
      return;
    }

    try {
      String transport = 'Train';
      String hotel = 'Standard';
      if (style == 'Budget') {
        transport = 'Bus';
        hotel = 'Budget';
      } else if (style == 'Luxury') {
        transport = 'Flight';
        hotel = 'Luxury';
      }

      final costRes = await ApiService.postRequest('/api/ml/predict-cost', {
        'destination': destination.trim(),
        'trip_days': 5, 
        'travelers_count': travelers,
        'transport_mode': transport,
        'season': 'Winter',
        'hotel_type': hotel,
        'traveler_type': style == 'Budget' ? 'Budget Traveler' : (style == 'Luxury' ? 'Luxury Vacationer' : 'Family Explorer')
      });

      if (costRes.statusCode != 200) {
        throw Exception(jsonDecode(costRes.body)['detail'] ?? "Cost Prediction Failed");
      }
      
      final costData = jsonDecode(costRes.body);
      final estimatedCost = (costData['predicted_cost_inr'] as num).toDouble();

      

      final prediction = TripPrediction(
        estimatedCost: estimatedCost,
        estimatedDurationDays: (costData['assumed_days'] as num).toInt(),
        confidenceScore: 0.91, 
      );

      state = state.copyWith(isLoading: false, prediction: prediction);
        } catch (e) {
      String rawError = e.toString();
      String safeError = "Unable to connect to the AI model. Please check your internet and try again.";
      
      // If it's a clean user-facing error from our backend logic (like missing fields, or custom ValueError)
      if (!rawError.contains("FormatException") && !rawError.contains("TypeError") && !rawError.contains("Internal Server Error")) {
          safeError = rawError.replaceAll("Exception: ", "");
      }
      
      state = state.copyWith(isLoading: false, error: safeError);
    }
  }
}

final predictorProvider = NotifierProvider<PredictorNotifier, PredictorState>(PredictorNotifier.new);
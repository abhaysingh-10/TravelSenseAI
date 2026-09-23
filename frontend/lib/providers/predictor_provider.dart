import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prediction_model.dart';
import 'dart:math';

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

    // Simulate AI model latency
    await Future.delayed(const Duration(seconds: 2));

    if (destination.trim().isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Please enter a destination');
      return;
    }

    // Generate dummy prediction logic
    final random = Random();
    
    // Base cost per day per traveler based on style
    double baseCost = 2000.0;
    if (style == 'Luxury') baseCost = 8000.0;
    if (style == 'Standard') baseCost = 4000.0;

    final dummyDuration = random.nextInt(7) + 3; // 3 to 9 days
    final dummyCost = baseCost * dummyDuration * travelers;
    final dummyConfidence = 0.75 + (random.nextDouble() * 0.2); // 0.75 to 0.95

    final prediction = TripPrediction(
      estimatedCost: dummyCost,
      estimatedDurationDays: dummyDuration,
      confidenceScore: dummyConfidence,
    );

    state = state.copyWith(isLoading: false, prediction: prediction);
  }
}

final predictorProvider = NotifierProvider<PredictorNotifier, PredictorState>(PredictorNotifier.new);

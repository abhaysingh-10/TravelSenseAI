import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class SegmentationState {
  final bool isLoading;
  final String segment;
  
  SegmentationState({this.isLoading = true, this.segment = 'Analyzing...'});
}

class SegmentationNotifier extends Notifier<SegmentationState> {
  @override
  SegmentationState build() {
    fetchSegment();
    return SegmentationState();
  }

  Future<void> fetchSegment() async {
    try {
      final response = await ApiService.getRequest('/api/ml/segmentation');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = SegmentationState(
          isLoading: false,
          segment: data['traveler_segment'] ?? 'Unknown Segment',
        );
      } else {
        state = SegmentationState(isLoading: false, segment: 'Unable to analyze');
      }
    } catch (e) {
      state = SegmentationState(isLoading: false, segment: 'New Traveler');
    }
  }
}

final segmentationProvider = NotifierProvider<SegmentationNotifier, SegmentationState>(SegmentationNotifier.new);

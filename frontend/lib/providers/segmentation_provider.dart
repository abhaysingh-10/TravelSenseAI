import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class SegmentationState {
  final bool isLoading;
  final String segment;
  
  SegmentationState({this.isLoading = true, this.segment = 'Analyzing...'});
}

class SegmentationNotifier extends Notifier<SegmentationState> {
  @override
  SegmentationState build() {
    final authState = ref.watch(authProvider);
    if (authState.accessToken != null) {
      Future.microtask(() => fetchSegment());
      return SegmentationState(isLoading: true, segment: 'Analyzing...');
    }
    return SegmentationState(isLoading: false, segment: 'New Traveler');
  }

  Future<void> fetchSegment() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        state = SegmentationState(isLoading: false, segment: 'New Traveler');
        return;
      }
      final response = await ApiService.getRequest('/api/ml/segmentation');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final segment = data['traveler_segment'] as String? ?? 'New Traveler';
        state = SegmentationState(
          isLoading: false,
          segment: segment,
        );
      } else {
        state = SegmentationState(isLoading: false, segment: state.segment);
      }
    } catch (e) {
      state = SegmentationState(isLoading: false, segment: state.segment);
    }
  }
}

final segmentationProvider = NotifierProvider<SegmentationNotifier, SegmentationState>(SegmentationNotifier.new);

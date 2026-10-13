import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'expense_provider.dart';
import 'trip_provider.dart';

class DashboardStats {
  final double totalLifetimeSpent;
  final double averageCostPerTrip;
  final int totalTrips;
  final Map<String, double> spendingByCategory;
  final Map<String, double> monthlySpending;
  final bool isLoading;
  final String? error;

  DashboardStats({
    required this.totalLifetimeSpent,
    required this.averageCostPerTrip,
    required this.totalTrips,
    required this.spendingByCategory,
    required this.monthlySpending,
    this.isLoading = false,
    this.error,
  });

  factory DashboardStats.empty({bool isLoading = false}) {
    return DashboardStats(
      totalLifetimeSpent: 0.0,
      averageCostPerTrip: 0.0,
      totalTrips: 0,
      spendingByCategory: {},
      monthlySpending: {},
      isLoading: isLoading,
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final catMap = <String, double>{};
    if (json['spendingByCategory'] != null) {
      final rawCat = json['spendingByCategory'] as Map<String, dynamic>;
      rawCat.forEach((k, v) {
        catMap[k] = (v as num).toDouble();
      });
    }

    final monthMap = <String, double>{};
    if (json['monthlySpending'] != null) {
      final rawMonth = json['monthlySpending'] as Map<String, dynamic>;
      rawMonth.forEach((k, v) {
        monthMap[k] = (v as num).toDouble();
      });
    }

    return DashboardStats(
      totalLifetimeSpent: ((json['totalLifetimeSpent'] ?? 0.0) as num).toDouble(),
      averageCostPerTrip: ((json['averageCostPerTrip'] ?? 0.0) as num).toDouble(),
      totalTrips: (json['totalTrips'] ?? 0) as int,
      spendingByCategory: catMap,
      monthlySpending: monthMap,
      isLoading: false,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardStats> {
  @override
  DashboardStats build() {
    // Reactively watch trips and expenses so adding/editing an expense
    // or trip automatically refreshes the dynamic dashboard analytics
    ref.watch(tripListProvider);
    ref.watch(expenseListProvider);

    Future.microtask(() => fetchAnalytics());

    return DashboardStats.empty(isLoading: true);
  }

  Future<void> fetchAnalytics() async {
    try {
      final response = await ApiService.getRequest('/api/analytics/dashboard');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = DashboardStats.fromJson(data);
      } else {
        state = DashboardStats(
          totalLifetimeSpent: state.totalLifetimeSpent,
          averageCostPerTrip: state.averageCostPerTrip,
          totalTrips: state.totalTrips,
          spendingByCategory: state.spendingByCategory,
          monthlySpending: state.monthlySpending,
          isLoading: false,
          error: 'Failed to fetch analytics (Status ${response.statusCode})',
        );
      }
    } catch (e) {
      state = DashboardStats(
        totalLifetimeSpent: state.totalLifetimeSpent,
        averageCostPerTrip: state.averageCostPerTrip,
        totalTrips: state.totalTrips,
        spendingByCategory: state.spendingByCategory,
        monthlySpending: state.monthlySpending,
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardStats>(DashboardNotifier.new);

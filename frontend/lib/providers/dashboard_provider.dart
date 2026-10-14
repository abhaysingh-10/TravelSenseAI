import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'expense_provider.dart';
import 'trip_provider.dart';

class TripBenchmark {
  final int tripId;
  final String destination;
  final double actualSpent;
  final double predictedCost;
  final double difference;
  final bool isUnderBudget;
  final int days;

  TripBenchmark({
    required this.tripId,
    required this.destination,
    required this.actualSpent,
    required this.predictedCost,
    required this.difference,
    required this.isUnderBudget,
    required this.days,
  });

  factory TripBenchmark.fromJson(Map<String, dynamic> json) {
    return TripBenchmark(
      tripId: json['tripId'] as int,
      destination: (json['destination'] ?? '') as String,
      actualSpent: ((json['actualSpent'] ?? 0.0) as num).toDouble(),
      predictedCost: ((json['predictedCost'] ?? 0.0) as num).toDouble(),
      difference: ((json['difference'] ?? 0.0) as num).toDouble(),
      isUnderBudget: (json['isUnderBudget'] ?? false) as bool,
      days: (json['days'] ?? 1) as int,
    );
  }
}

class BudgetEfficiency {
  final int score;
  final double totalPredicted;
  final double totalActual;
  final double netSavings;
  final String status;
  final List<TripBenchmark> tripBenchmarks;

  BudgetEfficiency({
    required this.score,
    required this.totalPredicted,
    required this.totalActual,
    required this.netSavings,
    required this.status,
    required this.tripBenchmarks,
  });

  factory BudgetEfficiency.fromJson(Map<String, dynamic> json) {
    var list = <TripBenchmark>[];
    if (json['tripBenchmarks'] != null) {
      final rawList = json['tripBenchmarks'] as List<dynamic>;
      list = rawList.map((item) => TripBenchmark.fromJson(item as Map<String, dynamic>)).toList();
    }
    return BudgetEfficiency(
      score: (json['score'] ?? 0) as int,
      totalPredicted: ((json['totalPredicted'] ?? 0.0) as num).toDouble(),
      totalActual: ((json['totalActual'] ?? 0.0) as num).toDouble(),
      netSavings: ((json['netSavings'] ?? 0.0) as num).toDouble(),
      status: (json['status'] ?? '') as String,
      tripBenchmarks: list,
    );
  }
}

class DashboardStats {
  final double totalLifetimeSpent;
  final double averageCostPerTrip;
  final int totalTrips;
  final Map<String, double> spendingByCategory;
  final Map<String, double> monthlySpending;
  final BudgetEfficiency? budgetEfficiency;
  final bool isLoading;
  final String? error;

  DashboardStats({
    required this.totalLifetimeSpent,
    required this.averageCostPerTrip,
    required this.totalTrips,
    required this.spendingByCategory,
    required this.monthlySpending,
    this.budgetEfficiency,
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
      budgetEfficiency: null,
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

    BudgetEfficiency? budgetEff;
    if (json['budgetEfficiency'] != null) {
      budgetEff = BudgetEfficiency.fromJson(json['budgetEfficiency'] as Map<String, dynamic>);
    }

    return DashboardStats(
      totalLifetimeSpent: ((json['totalLifetimeSpent'] ?? 0.0) as num).toDouble(),
      averageCostPerTrip: ((json['averageCostPerTrip'] ?? 0.0) as num).toDouble(),
      totalTrips: (json['totalTrips'] ?? 0) as int,
      spendingByCategory: catMap,
      monthlySpending: monthMap,
      budgetEfficiency: budgetEff,
      isLoading: false,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardStats> {
  bool _isFetching = false;

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
    if (_isFetching) return;
    _isFetching = true;
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
          budgetEfficiency: state.budgetEfficiency,
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
        budgetEfficiency: state.budgetEfficiency,
        isLoading: false,
        error: e.toString(),
      );
    } finally {
      _isFetching = false;
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardStats>(DashboardNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardStats {
  final double totalLifetimeSpent;
  final double averageCostPerTrip;
  final int totalTrips;
  final Map<String, double> spendingByCategory;
  final Map<String, double> monthlySpending;

  DashboardStats({
    required this.totalLifetimeSpent,
    required this.averageCostPerTrip,
    required this.totalTrips,
    required this.spendingByCategory,
    required this.monthlySpending,
  });
}

class DashboardNotifier extends Notifier<DashboardStats> {
  @override
  DashboardStats build() {


    
    // Dummy Data for Phase 1
    return DashboardStats(
      totalLifetimeSpent: 125400.0,
      averageCostPerTrip: 25080.0,
      totalTrips: 5,
      spendingByCategory: {
        'Flights': 45000.0,
        'Hotels': 38000.0,
        'Food': 22000.0,
        'Activities': 15000.0,
        'Other': 5400.0,
      },
      monthlySpending: {
        'Jan': 12000.0,
        'Feb': 18000.0,
        'Mar': 0.0,
        'Apr': 25000.0,
        'May': 42000.0,
        'Jun': 28400.0,
      },
    );
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardStats>(DashboardNotifier.new);

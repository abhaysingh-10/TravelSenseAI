import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    final formatCurrency = NumberFormat('#,##0');

    final colorMap = {
      'Flight': Colors.blue.shade400,
      'Flights': Colors.blue.shade400,
      'Transport': Colors.teal.shade400,
      'Accommodation': Colors.orange.shade400,
      'Hotels': Colors.orange.shade400,
      'Food': Colors.green.shade400,
      'Activities': Colors.purple.shade400,
      'Other': Colors.grey.shade400,
    };

    Color getCategoryColor(String category, int index) {
      if (colorMap.containsKey(category)) return colorMap[category]!;
      final fallbackColors = [
        Colors.indigo.shade400,
        Colors.amber.shade600,
        Colors.pink.shade400,
        Colors.cyan.shade400,
      ];
      return fallbackColors[index % fallbackColors.length];
    }

    // Dynamic maxY for monthly spending bar chart
    final maxMonthly = stats.monthlySpending.values.fold<double>(
      0.0,
      (prev, elem) => elem > prev ? elem : prev,
    );
    final barMaxY = maxMonthly > 0 ? (maxMonthly * 1.25) : 10000.0;
    final interval = (barMaxY / 4).clamp(100.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).fetchAnalytics();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Analytics',
                        style: TextStyle(
                          color: Color(0xFF121C2C),
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF121C2C)),
                        tooltip: 'Refresh Analytics',
                        onPressed: () {
                          ref.read(dashboardProvider.notifier).fetchAnalytics();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              if (stats.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Total Spent Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL LIFETIME SPENT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${formatCurrency.format(stats.totalLifetimeSpent)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Trips', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${stats.totalTrips}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Avg Per Trip', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${formatCurrency.format(stats.averageCostPerTrip)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text('Spending Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF121C2C))),
                    const SizedBox(height: 16),

                    // Bar Chart
                    Container(
                      height: 220,
                      padding: const EdgeInsets.only(top: 24, right: 24, left: 16, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 8))
                        ],
                      ),
                      child: stats.monthlySpending.isEmpty
                          ? Center(
                              child: Text(
                                'No monthly spending data yet',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: barMaxY,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final months = stats.monthlySpending.keys.toList();
                                      final month = groupIndex < months.length ? months[groupIndex] : '';
                                      return BarTooltipItem(
                                        '$month\n₹${formatCurrency.format(rod.toY)}',
                                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (double value, TitleMeta meta) {
                                        final months = stats.monthlySpending.keys.toList();
                                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              months[value.toInt()],
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                      reservedSize: 28,
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: interval,
                                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                                ),
                                barGroups: stats.monthlySpending.entries.toList().asMap().entries.map((entry) {
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.value,
                                        color: Theme.of(context).primaryColor,
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          toY: barMaxY,
                                          color: Colors.grey.shade100,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ),

                    const SizedBox(height: 32),
                    const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF121C2C))),
                    const SizedBox(height: 16),

                    // Donut Chart & Legend
                    if (stats.spendingByCategory.isEmpty || stats.totalLifetimeSpent <= 0)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text(
                                'No Expenses Logged Yet',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF121C2C)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add expenses to your trips to see your category breakdown here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 60,
                                  sections: stats.spendingByCategory.entries.toList().asMap().entries.map((indexed) {
                                    final entry = indexed.value;
                                    final totalExpenses = stats.spendingByCategory.values.fold<double>(0.0, (s, v) => s + v);
                                    final percentage = totalExpenses > 0
                                        ? (entry.value / totalExpenses * 100).toStringAsFixed(0)
                                        : '0';
                                    return PieChartSectionData(
                                      color: getCategoryColor(entry.key, indexed.key),
                                      value: entry.value,
                                      title: '$percentage%',
                                      radius: 24,
                                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Legend
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: stats.spendingByCategory.entries.toList().asMap().entries.map((indexed) {
                                final entry = indexed.value;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: getCategoryColor(entry.key, indexed.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        Text(
                                          '₹${formatCurrency.format(entry.value)}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                    // Extra bottom padding so full card & legend clear the BottomNavigationBar when scrolling
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

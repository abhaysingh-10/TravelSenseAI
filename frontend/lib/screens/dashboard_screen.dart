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

                    if (stats.budgetEfficiency != null) ...[
                      const SizedBox(height: 24),
                      _buildBudgetEfficiencyCard(context, stats.budgetEfficiency!, formatCurrency),
                      if (stats.budgetEfficiency!.tripBenchmarks.isNotEmpty)
                        _buildTripBenchmarksList(context, stats.budgetEfficiency!.tripBenchmarks, formatCurrency),
                    ],

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

  Widget _buildBudgetEfficiencyCard(
    BuildContext context,
    BudgetEfficiency eff,
    NumberFormat formatCurrency,
  ) {
    final isSmartSpender = eff.netSavings >= 0;
    final scoreColor = eff.score >= 80
        ? const Color(0xFF10B981) // Emerald green
        : eff.score >= 60
            ? const Color(0xFFF59E0B) // Amber
            : const Color(0xFFEF4444); // Red

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with AI badge and Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Budget Efficiency',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF121C2C),
                        ),
                      ),
                      Text(
                        'ML Benchmark vs. Actual Spend',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Efficiency Score Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      eff.score >= 80 ? Icons.verified_rounded : Icons.speed_rounded,
                      color: scoreColor,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${eff.score}/100',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (eff.tripBenchmarks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Log expenses on your trips to view real-time ML budget efficiency and savings analysis.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Net Savings Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSmartSpender ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSmartSpender ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSmartSpender ? Icons.savings_outlined : Icons.trending_up_rounded,
                    color: isSmartSpender ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSmartSpender
                              ? '₹${formatCurrency.format(eff.netSavings)} Saved'
                              : '₹${formatCurrency.format(eff.netSavings.abs())} Over Forecast',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isSmartSpender ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          eff.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSmartSpender ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2-Column Comparison Row (Actual vs ML Benchmark)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTUAL SPENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${formatCurrency.format(eff.totalActual)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ML BENCHMARK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${formatCurrency.format(eff.totalPredicted)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripBenchmarksList(
    BuildContext context,
    List<TripBenchmark> benchmarks,
    NumberFormat formatCurrency,
  ) {
    if (benchmarks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trip Benchmarks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121C2C),
              ),
            ),
            Text(
              '${benchmarks.length} evaluated',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: benchmarks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = benchmarks[index];
            final isUnder = item.isUnderBudget;
            final diffText = isUnder
                ? '-₹${formatCurrency.format(item.difference)}'
                : '+₹${formatCurrency.format(item.difference.abs())}';

            final badgeBg = isUnder ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
            final badgeTextColor = isUnder ? const Color(0xFF059669) : const Color(0xFFDC2626);
            final badgeBorder = isUnder ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA);

            final maxVal = item.predictedCost > item.actualSpent ? item.predictedCost : item.actualSpent;
            final ratio = maxVal > 0 ? (item.actualSpent / maxVal).clamp(0.0, 1.0) : 0.0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              size: 16,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.destination,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '${item.days} ${item.days == 1 ? "day" : "days"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUnder ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              size: 12,
                              color: badgeTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              diffText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFEEF2F6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUnder ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spent: ₹${formatCurrency.format(item.actualSpent)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        'AI Model: ₹${formatCurrency.format(item.predictedCost)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

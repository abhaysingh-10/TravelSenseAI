import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';
import '../providers/trip_provider.dart';
import '../providers/expense_provider.dart';
import 'add_edit_trip_screen.dart';
import 'add_edit_expense_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch trips
    final trips = ref.watch(tripListProvider);
    final currentTripIndex = trips.indexWhere((t) => t.id == trip.id);
    
    if (currentTripIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    final currentTrip = trips[currentTripIndex];
    
    // Watch expenses for this trip
    final expenses = ref.watch(tripExpensesProvider(currentTrip.id));
    
    // Dynamically calculate spent amount from actual expenses
    final double actualSpent = expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    
    final progress = actualSpent / currentTrip.budget;
    final isOverBudget = progress > 1.0;
    final formatCurrency = NumberFormat('#,##0');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditTripScreen(trip: currentTrip),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                    onPressed: () => _showDeleteConfirmation(context, ref, currentTrip),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                currentTrip.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 40),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          currentTrip.destination,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: Color(0xFF111418),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded, size: 16, color: Colors.orange.shade400),
                            const SizedBox(width: 6),
                            Text(
                              '${currentTrip.weatherTemp}°C',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('MMM d').format(currentTrip.startDate)} - ${dateFormat.format(currentTrip.endDate)}',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Budget Overview Title
                  const Text(
                    'Budget Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111418)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Budget Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TOTAL BUDGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade500)),
                                const SizedBox(height: 8),
                                Text('₹${formatCurrency.format(currentTrip.budget)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111418))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('SPENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey.shade500)),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${formatCurrency.format(actualSpent)}', 
                                  style: TextStyle(
                                    fontSize: 22, 
                                    fontWeight: FontWeight.w800,
                                    color: isOverBudget ? Colors.red.shade400 : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? Colors.red.shade400 : Theme.of(context).primaryColor,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        if (isOverBudget)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade400),
                                const SizedBox(width: 8),
                                Text(
                                  'Over budget by ₹${formatCurrency.format(actualSpent - currentTrip.budget)}',
                                  style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Expenses Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Expenses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111418)),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditExpenseScreen(tripId: currentTrip.id),
                            ),
                          );
                        },
                        icon: Icon(Icons.add, size: 16, color: Theme.of(context).primaryColor),
                        label: Text('Add', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Expenses List
                  expenses.isEmpty 
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 32, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No expenses added yet',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: expenses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          // Reverse list to show newest first
                          final exp = expenses[expenses.length - 1 - index];
                          return _buildExpenseCard(context, ref, exp, formatCurrency, dateFormat);
                        },
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, WidgetRef ref, Expense exp, NumberFormat formatCurrency, DateFormat dateFormat) {
    IconData getCategoryIcon(String category) {
      switch (category) {
        case 'Flight': return Icons.flight_takeoff;
        case 'Transport': return Icons.directions_car_outlined;
        case 'Accommodation': return Icons.hotel_outlined;
        case 'Food': return Icons.restaurant_outlined;
        case 'Activities': return Icons.local_activity_outlined;
        default: return Icons.receipt_outlined;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditExpenseScreen(tripId: exp.tripId, expense: exp),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(getCategoryIcon(exp.category), color: Colors.grey.shade700, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111418)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(exp.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              '₹${formatCurrency.format(exp.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111418)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              ref.read(tripListProvider.notifier).deleteTrip(trip.id);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';
import 'add_edit_trip_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripListProvider);
    
    final currentTripIndex = trips.indexWhere((t) => t.id == trip.id);
    
    if (currentTripIndex == -1) {


      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentTrip = trips[currentTripIndex];
    final progress = currentTrip.spent / currentTrip.budget;
    final isOverBudget = progress > 1.0;
    final formatCurrency = NumberFormat('#,##0');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditTripScreen(trip: currentTrip),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showDeleteConfirmation(context, ref, currentTrip),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    currentTrip.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for text readability
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            color: const Color(0xFF121C2C),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.orange.shade400),
                            const SizedBox(width: 4),
                            Text(
                              '${currentTrip.weatherTemp}°C',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('MMM d').format(currentTrip.startDate)} - ${DateFormat('MMM d, yyyy').format(currentTrip.endDate)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Budget Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Budget Overview',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).primaryColor),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Budget', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text('₹${formatCurrency.format(currentTrip.budget)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Spent', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${formatCurrency.format(currentTrip.spent)}', 
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: isOverBudget ? Colors.red.shade400 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              'You are over budget by ₹${formatCurrency.format(currentTrip.spent - currentTrip.budget)}',
                              style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Future expansion for expenses/itinerary
                  Center(
                    child: Text(
                      'Expenses & Itinerary coming soon...',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              ref.read(tripListProvider.notifier).deleteTrip(trip.id);
              Navigator.pop(ctx); // Close dialog
              // The screen itself will pop automatically because currentTripIndex will be -1
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}

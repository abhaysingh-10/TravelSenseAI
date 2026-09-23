import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/predictor_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class TripPredictorScreen extends ConsumerStatefulWidget {
  const TripPredictorScreen({super.key});

  @override
  ConsumerState<TripPredictorScreen> createState() => _TripPredictorScreenState();
}

class _TripPredictorScreenState extends ConsumerState<TripPredictorScreen> {
  final _destinationController = TextEditingController();
  String _selectedStyle = 'Standard';
  int _travelers = 1;

  final List<String> _styles = ['Budget', 'Standard', 'Luxury'];

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _runPrediction() {
    FocusScope.of(context).unfocus();
    ref.read(predictorProvider.notifier).predictTrip(
      _destinationController.text,
      _selectedStyle,
      _travelers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictorProvider);
    final formatCurrency = NumberFormat('#,##0');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'AI Predictor',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  color: const Color(0xFF121C2C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estimate costs and duration for your next adventure using our ML models.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Form
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
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomInputField(
                      labelText: 'Where do you want to go?',
                      controller: _destinationController,
                    ),
                    const SizedBox(height: 20),
                    
                    Text('Travel Style', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStyle,
                          isExpanded: true,
                          items: _styles.map((style) => DropdownMenuItem(value: style, child: Text(style))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStyle = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Number of Travelers: $_travelers', style: Theme.of(context).textTheme.labelMedium),
                    Slider(
                      value: _travelers.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: Theme.of(context).primaryColor,
                      label: _travelers.toString(),
                      onChanged: (val) {
                        setState(() => _travelers = val.toInt());
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: state.isLoading ? 'Predicting...' : 'Predict Trip Cost',
                        onPressed: state.isLoading ? () {} : _runPrediction,
                      ),
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: Text(
                            state.error!,
                            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Result Card
              if (state.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.prediction != null)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AI PREDICTION',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          Icon(Icons.auto_awesome, color: Colors.amber.shade300, size: 20),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Estimated Cost',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${formatCurrency.format(state.prediction!.estimatedCost)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Duration', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '${state.prediction!.estimatedDurationDays} Days',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Confidence', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '${(state.prediction!.confidenceScore * 100).toInt()}%',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class AddEditTripScreen extends ConsumerStatefulWidget {
  final Trip?
      trip; // If null, we're adding a new trip. If provided, we're editing.

  const AddEditTripScreen({super.key, this.trip});

  @override
  ConsumerState<AddEditTripScreen> createState() => _AddEditTripScreenState();
}

class _AddEditTripScreenState extends ConsumerState<AddEditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _destinationController;
  late TextEditingController _budgetController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _destinationController =
        TextEditingController(text: widget.trip?.destination ?? '');
    _budgetController = TextEditingController(
        text:
            widget.trip != null ? widget.trip!.budget.toStringAsFixed(0) : '');
    _startDate = widget.trip?.startDate;
    _endDate = widget.trip?.endDate;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()));

    final firstDate = isStart ? DateTime.now() : (_startDate ?? DateTime.now());

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
          // Reset end date if it's before new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _saveTrip() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select both start and end dates.')),
        );
        return;
      }

      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('End date cannot be before start date.')),
        );
        return;
      }

      final destination = _destinationController.text.trim();
      final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

      if (widget.trip == null) {
        // Add new
        ref.read(tripListProvider.notifier).addTrip(
              destination,
              _startDate!,
              _endDate!,
              budget,
            );
      } else {
        // Update existing
        final updatedTrip = widget.trip!.copyWith(
          destination: destination,
          startDate: _startDate,
          endDate: _endDate,
          budget: budget,
        );
        ref.read(tripListProvider.notifier).updateTrip(updatedTrip);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.trip != null;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Trip' : 'Add New Trip',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomInputField(
                  labelText: 'Destination',
                  controller: _destinationController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a destination';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Date',
                                  style: theme.textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text(
                                _startDate == null
                                    ? 'Select Date'
                                    : dateFormat.format(_startDate!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _startDate == null
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Date',
                                  style: theme.textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text(
                                _endDate == null
                                    ? 'Select Date'
                                    : dateFormat.format(_endDate!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _endDate == null
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  labelText: 'Budget',
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a budget';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    if (amount < 0) {
                      return 'Budget cannot be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: isEditing ? 'Save Changes' : 'Create Trip',
                  onPressed: _saveTrip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;
  final Expense? expense; // If null, add new; if provided, edit

  const AddEditExpenseScreen({super.key, required this.tripId, this.expense});

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  String _selectedCategory = 'Food';
  DateTime? _selectedDate;

  final List<String> _categories = [
    'Flight',
    'Transport',
    'Accommodation',
    'Food',
    'Activities',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(text: widget.expense != null ? widget.expense!.amount.toStringAsFixed(0) : '');
    _selectedCategory = widget.expense?.category ?? 'Food';
    _selectedDate = widget.expense?.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveExpense() {
    // Task 1: Basic save logic. (Task 2 will add strict validation here later)
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final dateToSave = _selectedDate ?? DateTime.now();

    if (widget.expense == null) {
      // Add
      ref.read(expenseListProvider.notifier).addExpense(
        widget.tripId,
        title,
        amount,
        _selectedCategory,
        dateToSave,
      );
    } else {
      // Edit
      final updated = widget.expense!.copyWith(
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: dateToSave,
      );
      ref.read(expenseListProvider.notifier).updateExpense(updated);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111418)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF111418)),
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
                  labelText: 'Expense Title',
                  controller: _titleController,
                  // No strict validator yet (Task 2)
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  labelText: 'Amount (₹)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  // No strict validator yet (Task 2)
                ),
                const SizedBox(height: 20),
                
                // Category Dropdown
                Text('Category', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                // Date Picker
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate == null ? 'Select Date' : dateFormat.format(_selectedDate!),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _selectedDate == null ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: isEditing ? 'Save Changes' : 'Add Expense',
                  onPressed: _saveExpense,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

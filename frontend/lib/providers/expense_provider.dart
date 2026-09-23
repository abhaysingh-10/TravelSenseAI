import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';

const uuid = Uuid();

class ExpenseListNotifier extends Notifier<List<Expense>> {
  @override
  List<Expense> build() {
    // Dummy expenses mapped to the dummy trips (trip id '1', '2', '3')
    return [
      Expense(id: 'e1', tripId: '1', title: 'Flight to Kullu', amount: 4500, category: 'Flight', date: DateTime(2024, 5, 10)),
      Expense(id: 'e2', tripId: '1', title: 'Hotel booking', amount: 3000, category: 'Accommodation', date: DateTime(2024, 5, 10)),
      Expense(id: 'e3', tripId: '2', title: 'Seafood dinner', amount: 1500, category: 'Food', date: DateTime(2024, 4, 21)),
    ];
  }

  void addExpense(String tripId, String title, double amount, String category, DateTime date) {
    final newExpense = Expense(
      id: uuid.v4(),
      tripId: tripId,
      title: title,
      amount: amount,
      category: category,
      date: date,
    );
    state = [...state, newExpense];
  }

  void updateExpense(Expense updatedExpense) {
    state = [
      for (final exp in state)
        if (exp.id == updatedExpense.id) updatedExpense else exp
    ];
  }

  void deleteExpense(String id) {
    state = state.where((exp) => exp.id != id).toList();
  }
}

final expenseListProvider = NotifierProvider<ExpenseListNotifier, List<Expense>>(ExpenseListNotifier.new);

// Derived provider to get expenses for a specific trip
final tripExpensesProvider = Provider.family<List<Expense>, String>((ref, tripId) {
  final allExpenses = ref.watch(expenseListProvider);
  return allExpenses.where((exp) => exp.tripId == tripId).toList();
});

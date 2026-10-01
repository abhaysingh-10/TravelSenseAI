import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/api_service.dart';

class ExpenseListNotifier extends Notifier<List<Expense>> {
  @override
  List<Expense> build() {
    fetchExpenses();
    return [];
  }

  Future<void> fetchExpenses() async {
    try {
      final response = await ApiService.getRequest('/expenses');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = data.map((json) {
          json['id'] = json['id'].toString();
          json['trip_id'] = json['trip_id'].toString();
          return Expense.fromJson(json);
        }).toList();
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
  }

  Future<bool> addExpense(String tripId, String title, double amount, String category, DateTime date) async {
    final Map<String, dynamic> body = {
      'trip_id': int.parse(tripId), // backend expects int
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String().split('T')[0],
    };

    try {
      final response = await ApiService.postRequest('/expenses', body);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        json['id'] = json['id'].toString();
        json['trip_id'] = json['trip_id'].toString();
        final newExpense = Expense.fromJson(json);
        state = [...state, newExpense];
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding expense: $e');
      return false;
    }
  }

  Future<bool> updateExpense(Expense updatedExpense) async {
    final Map<String, dynamic> body = {
      'trip_id': int.parse(updatedExpense.tripId),
      'title': updatedExpense.title,
      'amount': updatedExpense.amount,
      'category': updatedExpense.category,
      'date': updatedExpense.date.toIso8601String().split('T')[0],
    };

    try {
      final response = await ApiService.putRequest('/expenses/${updatedExpense.id}', body);
      if (response.statusCode == 200) {
        state = [
          for (final exp in state)
            if (exp.id == updatedExpense.id) updatedExpense else exp
        ];
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      final response = await ApiService.deleteRequest('/expenses/$id');
      if (response.statusCode == 200) {
        state = state.where((exp) => exp.id != id).toList();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }
}

final expenseListProvider = NotifierProvider<ExpenseListNotifier, List<Expense>>(ExpenseListNotifier.new);

// Derived provider to get expenses for a specific trip
final tripExpensesProvider = Provider.family<List<Expense>, String>((ref, tripId) {
  final allExpenses = ref.watch(expenseListProvider);
  return allExpenses.where((exp) => exp.tripId == tripId).toList();
});

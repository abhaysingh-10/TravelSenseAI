import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'trip_provider.dart';
import 'expense_provider.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadToken();
    return AuthState();
  }

  Future<void> _loadToken() async {
    final token = await ApiService.getToken();
    if (token != null) {
      // For now, if we have a token, we consider the user authenticated.
      // Ideally, we'd fetch the user profile here, but we lack the endpoint.
      state = state.copyWith(
        accessToken: token,
        user: User(id: 'stored-id', email: 'user@example.com', fullName: 'User', isActive: true),
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoginLoading: true, error: null);

    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoginLoading: false, error: 'Email and password cannot be empty');
      return false;
    }

    try {
      // FastAPI's OAuth2PasswordRequestForm expects x-www-form-urlencoded data
      // with 'username' and 'password' fields.
      final response = await ApiService.postRequest(
        '/auth/login',
        {
          'username': email,
          'password': password,
        },
        isUrlEncoded: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        await ApiService.saveToken(token);

        // Create a dummy user object since the backend doesn't return one yet
        final user = User(id: 'mock-id', email: email, fullName: email.split('@')[0], isActive: true);

        state = state.copyWith(
          isLoginLoading: false,
          user: user,
          accessToken: token,
        );
        return true;
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(isLoginLoading: false, error: data['detail'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoginLoading: false, error: 'Network error occurred');
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isRegisterLoading: true, error: null);

    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      state = state.copyWith(isRegisterLoading: false, error: 'All fields are required');
      return false;
    }

    try {
      final response = await ApiService.postRequest(
        '/auth/register',
        {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Registration successful. Backend just returns {"message": "...", "user_id": 1}
        // Let's automatically log them in or just mock the state for now.
        // It's better to auto-login.
        return await login(email, password);
      } else {
        final data = jsonDecode(response.body);
        state = state.copyWith(isRegisterLoading: false, error: data['detail'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isRegisterLoading: false, error: 'Network error occurred');
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.deleteToken();
    state = AuthState();
    // Clear user data from memory so next login starts fresh
    ref.invalidate(tripListProvider);
    ref.invalidate(expenseListProvider);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

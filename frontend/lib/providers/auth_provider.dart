import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Email and password cannot be empty');
      return false;
    }

    // Dummy API Response matching exactly what FastAPI OAuth2 will return
    final mockResponse = {
      "access_token": "dummy_jwt_token_12345",
      "token_type": "bearer",
      "user": {
        "id": "uuid-123",
        "email": email,
        "full_name": "Test User",
        "is_active": true
      }
    };

    final user = User.fromJson(mockResponse['user'] as Map<String, dynamic>);
    
    state = state.copyWith(
      isLoading: false,
      user: user,
      accessToken: mockResponse['access_token'] as String,
    );
    
    return true;
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'All fields are required');
      return false;
    }

    // Dummy API Response matching FastAPI JSON shape
    final mockResponse = {
      "access_token": "dummy_jwt_token_67890",
      "token_type": "bearer",
      "user": {
        "id": "uuid-456",
        "email": email,
        "full_name": fullName,
        "is_active": true
      }
    };

    final user = User.fromJson(mockResponse['user'] as Map<String, dynamic>);
    
    state = state.copyWith(
      isLoading: false,
      user: user,
      accessToken: mockResponse['access_token'] as String,
    );
    
    return true;
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

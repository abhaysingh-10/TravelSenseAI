import os

user_model_path = 'frontend/lib/models/user_model.dart'
with open(user_model_path, 'r') as f: content = f.read()
content = content.replace('final bool isLoading;', 'final bool isLoginLoading;\n  final bool isRegisterLoading;')
content = content.replace('this.isLoading = false,', 'this.isLoginLoading = false,\n    this.isRegisterLoading = false,')
content = content.replace('bool? isLoading,', 'bool? isLoginLoading,\n    bool? isRegisterLoading,')
content = content.replace('isLoading: isLoading ?? this.isLoading,', 'isLoginLoading: isLoginLoading ?? this.isLoginLoading,\n      isRegisterLoading: isRegisterLoading ?? this.isRegisterLoading,')
with open(user_model_path, 'w') as f: f.write(content)

auth_provider_path = 'frontend/lib/providers/auth_provider.dart'
with open(auth_provider_path, 'r') as f: content = f.read()
content = content.replace('isLoading: true', 'isLoginLoading: true')
content = content.replace('isLoading: false', 'isLoginLoading: false')
# The above changed everything to isLoginLoading. Now fix the register method
content = content.replace('isLoginLoading: true, error: null);\n\n    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {\n      state = state.copyWith(isLoginLoading: false, error: \'All fields are required\');', 
                          'isRegisterLoading: true, error: null);\n\n    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {\n      state = state.copyWith(isRegisterLoading: false, error: \'All fields are required\');')
content = content.replace('isLoginLoading: false, error: data[\'detail\'] ?? \'Registration failed\');', 'isRegisterLoading: false, error: data[\'detail\'] ?? \'Registration failed\');')
content = content.replace('isLoginLoading: false, error: \'Network error occurred\');\n      return false;\n    }\n  }\n\n  Future<void> logout()', 'isRegisterLoading: false, error: \'Network error occurred\');\n      return false;\n    }\n  }\n\n  Future<void> logout()')
with open(auth_provider_path, 'w') as f: f.write(content)

login_path = 'frontend/lib/screens/login_screen.dart'
with open(login_path, 'r') as f: content = f.read()
content = content.replace('authState.isLoading', 'authState.isLoginLoading')
with open(login_path, 'w') as f: f.write(content)

register_path = 'frontend/lib/screens/register_screen.dart'
with open(register_path, 'r') as f: content = f.read()
content = content.replace('authState.isLoading', 'authState.isRegisterLoading')
with open(register_path, 'w') as f: f.write(content)

print("Done fixing auth loading states.")

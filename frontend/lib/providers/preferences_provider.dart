import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesNotifier extends Notifier<List<String>> {
  static const _storage = FlutterSecureStorage();
  static const _prefsKey = 'user_travel_preferences';

  @override
  List<String> build() {
    _loadPreferences();
    return ['Mountains', 'Road Trips'];
  }

  Future<void> _loadPreferences() async {
    try {
      final stored = await _storage.read(key: _prefsKey);
      if (stored != null) {
        final List<dynamic> list = jsonDecode(stored);
        if (list.isNotEmpty) {
          state = list.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
  }

  Future<void> updatePreferences(List<String> newPrefs) async {
    state = newPrefs;
    try {
      await _storage.write(key: _prefsKey, value: jsonEncode(newPrefs));
    } catch (_) {}
  }
}

final preferencesProvider = NotifierProvider<PreferencesNotifier, List<String>>(PreferencesNotifier.new);

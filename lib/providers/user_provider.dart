import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs_provider.dart';

const _nameKey = 'lemon_user_name';

class UserNameNotifier extends StateNotifier<String> {
  UserNameNotifier(this._ref) : super('there') {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final stored = prefs.getString(_nameKey);
    if (stored != null && stored.trim().isNotEmpty) {
      state = stored.trim();
    }
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    state = trimmed.isEmpty ? 'there' : trimmed;
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_nameKey, state);
  }
}

final userNameProvider =
    StateNotifierProvider<UserNameNotifier, String>((ref) {
  return UserNameNotifier(ref);
});
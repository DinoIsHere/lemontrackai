import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_prefs_provider.dart';

class NotificationSettings {
  const NotificationSettings({
    this.pushEnabled = true,
    this.remindersEnabled = true,
    this.emailEnabled = false,
  });

  final bool pushEnabled;
  final bool remindersEnabled;
  final bool emailEnabled;

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? remindersEnabled,
    bool? emailEnabled,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationSettings> {
  NotificationsNotifier(this._ref) : super(const NotificationSettings()) {
    _load();
  }

  final Ref _ref;
  static const _pushKey = 'notif_push';
  static const _remindersKey = 'notif_reminders';
  static const _emailKey = 'notif_email';

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    state = NotificationSettings(
      pushEnabled: prefs.getBool(_pushKey) ?? true,
      remindersEnabled: prefs.getBool(_remindersKey) ?? true,
      emailEnabled: prefs.getBool(_emailKey) ?? false,
    );
  }

  Future<void> _save() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_pushKey, state.pushEnabled);
    await prefs.setBool(_remindersKey, state.remindersEnabled);
    await prefs.setBool(_emailKey, state.emailEnabled);
  }

  void setPush(bool v) {
    state = state.copyWith(pushEnabled: v);
    _save();
  }

  void setReminders(bool v) {
    state = state.copyWith(remindersEnabled: v);
    _save();
  }

  void setEmail(bool v) {
    state = state.copyWith(emailEnabled: v);
    _save();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationSettings>((ref) {
  return NotificationsNotifier(ref);
});

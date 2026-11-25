import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const _threadsKey = 'threads';
  static const _messagesKey = 'messages'; // threadId -> list of messages
  static const _eventsKey = 'events';
  static const _blocksKey = 'time_blocks';
  static const _kanbanKey = 'kanban_cards';

  static Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // Threads
  static Future<Map<String, dynamic>> getThreadsJson() async {
    final prefs = await _prefs;
    final str = prefs.getString(_threadsKey);
    if (str == null || str.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(str));
  }

  static Future<void> saveThreadsJson(Map<String, dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(_threadsKey, jsonEncode(data));
  }

  // Messages
  static Future<Map<String, dynamic>> getMessagesJson() async {
    final prefs = await _prefs;
    final str = prefs.getString(_messagesKey);
    if (str == null || str.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(str));
  }

  static Future<void> saveMessagesJson(Map<String, dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(_messagesKey, jsonEncode(data));
  }

  // Events
  static Future<List<dynamic>> getEventsJson() async {
    final prefs = await _prefs;
    final str = prefs.getString(_eventsKey);
    if (str == null || str.isEmpty) return [];
    return jsonDecode(str) as List<dynamic>;
  }

  static Future<void> saveEventsJson(List<dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(_eventsKey, jsonEncode(data));
  }

  // Time blocks
  static Future<List<dynamic>> getBlocksJson() async {
    final prefs = await _prefs;
    final str = prefs.getString(_blocksKey);
    if (str == null || str.isEmpty) return [];
    return jsonDecode(str) as List<dynamic>;
  }

  static Future<void> saveBlocksJson(List<dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(_blocksKey, jsonEncode(data));
  }

  // Kanban
  static Future<List<dynamic>> getKanbanJson() async {
    final prefs = await _prefs;
    final str = prefs.getString(_kanbanKey);
    if (str == null || str.isEmpty) return [];
    return jsonDecode(str) as List<dynamic>;
  }

  static Future<void> saveKanbanJson(List<dynamic> data) async {
    final prefs = await _prefs;
    await prefs.setString(_kanbanKey, jsonEncode(data));
  }
}

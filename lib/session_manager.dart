import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final Set<String> _cleanedRooms = {};

  static Future<void> flushAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('chat_')) await prefs.remove(key);
    }
    _cleanedRooms.clear();
  }

  static Future<bool> shouldWipeRoom(String roomId) async {
    if (!_cleanedRooms.contains(roomId)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_$roomId');
      _cleanedRooms.add(roomId);
      return true;
    }
    return false;
  }

  static Future<void> clearRoom(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_$roomId');
    _cleanedRooms.remove(roomId);
  }
}

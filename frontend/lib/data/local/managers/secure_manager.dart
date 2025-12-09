import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureManager {
  const SecureManager();

  final _storage = const FlutterSecureStorage();

  Future<String> get(
    String key, {
    String fallback = '',
  }) async {
    try {
      var value = await _storage.read(key: key);
      if (value == null || value.isEmpty) {
        return fallback;
      }
      return value;
    } catch (error) {
      return fallback;
    }
  }

  Future<void> save(String key, String value) async {
    try {
      return await _storage.write(key: key, value: value);
    } catch (e) {
      return;
    }
  }

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clear() => _storage.deleteAll();
}

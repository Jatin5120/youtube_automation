import '../../app.dart';

class DbClient {
  final SecureManager _secureManager = const SecureManager();
  final HiveManager _hiveManager = const HiveManager();

  Future<void> init() async {
    await _hiveManager.init();
  }

  T get<T>(
    String key, {
    T? fallback,
  }) =>
      _hiveManager.get<T>(key, fallback: fallback);

  Future<String> getSecure(
    String key, {
    String fallback = '',
  }) =>
      _secureManager.get(key, fallback: fallback);

  Future<void> save<T>(String key, T value) => _hiveManager.save<T>(key, value);

  Future<void> saveSecure(String key, String value) =>
      _secureManager.save(key, value);

  Future<void> delete(String key) => _hiveManager.delete(key);

  Future<void> deleteSecure(String key) => _secureManager.delete(key);

  Future<void> clear() => _hiveManager.clear();

  Future<void> clearSecure() => _secureManager.clear();
}

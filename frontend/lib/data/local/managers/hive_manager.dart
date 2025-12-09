import 'package:frontend/app.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveManager {
  const HiveManager();

  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(AppConstants.boxName),
    ]);
  }

  Box get _box => Hive.box(AppConstants.boxName);

  T get<T>(String key, {T? fallback}) => _box.get(key, defaultValue: fallback) as T;

  Future<void> save<T>(String key, T value) => _box.put(key, value);

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}

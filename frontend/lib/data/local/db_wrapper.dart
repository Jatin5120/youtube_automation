import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/res/res.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DBWrapper {
  const DBWrapper._() : flutterSecureStorage = const FlutterSecureStorage();

  final FlutterSecureStorage flutterSecureStorage;

  static const DBWrapper _service = DBWrapper._();

  static DBWrapper get i => _service;

  ///initialize the hive box
  Future<void> init({
    bool isTest = false,
  }) async {
    if (isTest) {
      Hive.init('HIVE_TEST');
    } else {
      await Hive.initFlutter();
    }
    await Hive.openBox<dynamic>(AppConstants.name);
  }

  /// Returns the box in which the data is stored.
  Box _getBox() => Hive.box<dynamic>(AppConstants.name);

  T? getValue<T>(String key) {
    var box = _getBox();
    return box.get(key, defaultValue: null) as T?;
  }

  ///to save a value
  Future<void> saveValue(dynamic key, dynamic value) async {
    await _getBox().put(key, value);
  }

  Future<String> getSecuredValue(String key) async {
    try {
      var value = await flutterSecureStorage.read(key: key);
      if (value == null || value.isEmpty) {
        value = '';
      }
      return value;
    } catch (error) {
      return '';
    }
  }

  Future<void> saveValueSecurely(
    String key,
    String value,
  ) =>
      flutterSecureStorage.write(
        key: key,
        value: value,
      );

  ///to clear data
  Future<void> deleteValue(String key) => _getBox().delete(key);

  /// clear all data
  Future<void> clearBox() async {
    await Future.wait([
      flutterSecureStorage.deleteAll(),
      _getBox().clear(),
    ]);
  }

  Future<void> deleteSecuredValue(String key) => flutterSecureStorage.delete(key: key);
}

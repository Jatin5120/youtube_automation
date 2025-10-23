import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../res/res.dart';

class AppLog {
  ///This Constructor of `AppLog` take 2 parameters
  ///```dart
  ///final dynamic message //This will be displayed in console
  ///final StackTrace? stackTrace //Optional
  ///```
  ///will be used to log the `message` with `red` color.
  ///
  ///It can be used for error logs
  ///
  ///You can use other constructors for different type of logs
  ///eg.
  ///- `AppLog()` - for basic log
  ///- `AppLog.info()` - for info log
  ///- `AppLog.success()` - for success log
  AppLog.error(this.message, [this.stackTrace]) {
    if (kDebugMode) {
      log(
        '\x1B[31m[${AppConstants.name}] - $message\x1B[0m',
        stackTrace: stackTrace,
        name: 'Error',
        level: 1200,
      );
    }
  }

  ///This Constructor of `AppLog` take 2 parameters
  ///```dart
  ///final dynamic message //This will be displayed in console
  ///final StackTrace? stackTrace //Optional
  ///```
  ///will be used to log the `message` with `green` color.
  ///
  ///It can be used for success logs
  ///
  ///You can use other constructors for different type of logs
  ///eg.
  ///- `AppLog()` - for basic log
  ///- `AppLog.info()` - for info log
  ///- `AppLog.error()` - for error log
  AppLog.success(this.message, [this.stackTrace]) {
    if (kDebugMode) {
      log(
        '\x1B[32m[${AppConstants.name}] - $message\x1B[0m',
        stackTrace: stackTrace,
        name: 'Success',
        level: 800,
      );
    }
  }

  ///This Constructor of `AppLog` take 2 parameters
  ///```dart
  ///final dynamic message //This will be displayed in console
  ///final StackTrace? stackTrace //Optional
  ///```
  ///will be used to log the `message` with `yellow` color.
  ///
  ///It can be used for information logs
  ///
  ///You can use other constructors for different type of logs
  ///eg.
  ///- `AppLog()` - for basic log
  ///- `AppLog.success()` - for success log
  ///- `AppLog.error()` - for error log
  AppLog.info(this.message, [this.stackTrace]) {
    if (kDebugMode) {
      log(
        '\x1B[33m[${AppConstants.name}] - $message\x1B[0m',
        stackTrace: stackTrace,
        name: 'Info',
        level: 900,
      );
    }
  }

  ///This Constructor of `AppLog` take 2 parameters
  ///```dart
  ///final dynamic message //This will be displayed in console
  ///final StackTrace? stackTrace //Optional
  ///```
  ///will be used to log the `message` with `white` color.
  ///
  ///It can be used for basic logs
  ///
  ///You can use other constructors for different type of logs
  ///eg.
  ///- `AppLog.info()` - for information log
  ///- `AppLog.success()` - for success log
  ///- `AppLog.error()` - for error log
  AppLog(this.message, [this.stackTrace]) {
    if (kDebugMode) {
      log(
        '\x1B[37m[${AppConstants.name}] - $message\x1B[0m',
        stackTrace: stackTrace,
        level: 700,
      );
    }
  }

  final dynamic message;
  final StackTrace? stackTrace;
}

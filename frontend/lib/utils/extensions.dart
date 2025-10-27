import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/app.dart';
import 'package:intl/intl.dart';

extension StyleExtension on TextStyle {
  TextStyle get withTitleColor {
    return copyWith(
      color: AppColors.titleDark,
    );
  }

  TextStyle get withBodyColor {
    return copyWith(
      color: AppColors.bodyDark,
    );
  }
}

extension ResponseExtension on ResponseModel {
  T body<T>() => jsonDecode(data)['data'] as T;

  String get message => jsonDecode(data)['data'] as String;
}

extension ObjectExtension on Object {
  String encrypt() {
    return base64.encode(utf8.encode(json.encode(this)));
  }
}

extension StringExtension on String {
  dynamic decrypt() {
    return json.decode(utf8.decode(base64.decode(this)));
  }
}

extension WidgetStateExtension on Set<WidgetState> {
  bool get isDisabled => any((e) => [WidgetState.disabled].contains(e));
}

extension DateExtension on DateTime {
  String get formatDate => DateFormat('dd/MM/yy').format(this);
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';

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

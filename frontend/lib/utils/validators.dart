import 'package:get/get.dart';

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}

class AppValidators {
  const AppValidators._();

  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Invalid Email';
    }

    return null;
  }

  static String? userName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    return null;
  }

  static String? phoneNumber(
    String? value, [
    int minLength = 10,
  ]) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (value.length < minLength) {
      return 'Phone must have atleast $minLength numbers';
    }
    return null;
  }

  static String? passwordValidator(String? value, [String? matchText]) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }

    if (!value.contains(RegExp('[a-z]'))) {
      return 'Password must contain atleast 1 lowercase character';
    }
    if (!value.contains(RegExp('[A-Z]'))) {
      return 'Password must contain atleast 1 uppercase character';
    }
    if (!value.contains(RegExp('[0-9]'))) {
      return 'Password must contain atleast 1 number';
    }
    // This Regex is to match special symbols
    if (!value.contains(RegExp('[^((0-9)|(a-z)|(A-Z)|)]'))) {
      return 'Password must contain atleast 1 special symbol';
    }
    if (value.length < 8) {
      return 'Password must contain atleast 8 characters';
    }
    if (matchText != null && matchText.trim().isNotEmpty) {
      if (value != matchText) {
        return "Password doesnt't match";
      }
    }
    return null;
  }

  static String? validateChannelId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Channel ID is required';
    }

    // YouTube channel ID format: UC followed by 22 characters
    if (!RegExp(r'^UC[a-zA-Z0-9_-]{22}$').hasMatch(value)) {
      return 'Invalid channel ID format';
    }

    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    // Username: 3-30 alphanumeric and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(value)) {
      return 'Invalid username format (3-30 characters, alphanumeric and underscores only)';
    }

    return null;
  }

  static List<String>? validateChannelList(String input, bool isChannelId) {
    final channels =
        input.replaceAll('@', '').replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim().split(' ').where((e) => e.isNotEmpty).toList();

    if (channels.isEmpty) {
      return null;
    }

    for (final channel in channels) {
      final error = isChannelId ? validateChannelId(channel) : validateUsername(channel);
      if (error != null) {
        throw ValidationException('$error: $channel');
      }
    }

    return channels;
  }
}

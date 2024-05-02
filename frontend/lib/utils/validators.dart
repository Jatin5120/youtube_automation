import 'package:get/get.dart';

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
}

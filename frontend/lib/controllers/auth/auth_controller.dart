import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/view_models/view_models.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  AuthController(this._viewModel);
  final AuthViewModel _viewModel;

  final loginKey = GlobalKey<FormState>();

  var emailTEC = TextEditingController();
  var passwordTEC = TextEditingController();

  void login() async {
    if (!(loginKey.currentState?.validate() ?? false)) {
      return;
    }
    var isLoggedIn = await _viewModel.login(
      emailTEC.text.trim(),
      passwordTEC.text.trim(),
    );

    if (isLoggedIn) {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }
}

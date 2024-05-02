import 'package:flutter/material.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  static const String route = AppRoutes.auth;

  static const String updateId = 'auth-view';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 700,
            maxWidth: 600,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GetBuilder<AuthController>(
              builder: (controller) {
                return Form(
                  key: controller.loginKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InputField(
                        controller: controller.emailTEC,
                        validator: AppValidators.emailValidator,
                        hint: 'Email id',
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        controller: controller.passwordTEC,
                        validator: AppValidators.passwordValidator,
                        hint: 'Password',
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        onTap: controller.login,
                        label: 'Login',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

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
                      const SizedBox(
                        height: 50,
                        child: AppIcon(),
                      ),
                      const SizedBox(height: 24),
                      AppText(
                        'Welcome Back!',
                        style: context.textTheme.titleSmall?.withTitleColor.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppText(
                        'Please sign in to continue',
                        style: context.textTheme.labelLarge?.withBodyColor,
                      ),
                      const SizedBox(height: 40),
                      InputField(
                        controller: controller.emailTEC,
                        validator: AppValidators.emailValidator,
                        hint: 'Email id',
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => InputField(
                          controller: controller.passwordTEC,
                          validator: AppValidators.passwordValidator,
                          hint: 'Password',
                          obscureText: controller.isObscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(controller.isObscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                            onPressed: () {
                              controller.isObscurePassword = !controller.isObscurePassword;
                            },
                          ),
                        ),
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

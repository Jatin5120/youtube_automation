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
                        onTap: controller.loginWithEmail,
                        label: 'Login',
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: Row(
                      //     crossAxisAlignment: CrossAxisAlignment.center,
                      //     children: [
                      //       const Flexible(child: Divider()),
                      //       const SizedBox(width: 8),
                      //       Text(
                      //         'OR',
                      //         style: context.textTheme.labelLarge?.copyWith(
                      //           color: context.theme.dividerTheme.color,
                      //         ),
                      //       ),
                      //       const SizedBox(width: 8),
                      //       const Flexible(child: Divider()),
                      //     ],
                      //   ),
                      // ),
                      // SizedBox(
                      //   width: double.maxFinite,
                      //   child: TapHandler(
                      //     onTap: controller.loginWithGoogle,
                      //     child: DecoratedBox(
                      //       decoration: BoxDecoration(
                      //         color: AppColors.cardLight,
                      //         borderRadius: BorderRadius.circular(8),
                      //       ),
                      //       child: Padding(
                      //         padding: const EdgeInsets.all(8.0),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             const AppSvg(
                      //               AssetConstants.google,
                      //               dimension: 24,
                      //             ),
                      //             const SizedBox(width: 8),
                      //             Text(
                      //               'Login with Google',
                      //               style: context.textTheme.labelMedium,
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
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

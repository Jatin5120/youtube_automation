import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.label,
    required this.button1,
    required this.button2,
  });

  final String label;
  final NavButtonWrapper button1;
  final NavButtonWrapper button2;

  @override
  Size get preferredSize => Size(Get.width, 120);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(label),
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.backgroundDark,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AppButton.small(
            onTap: button1.onTap,
            label: button1.label,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: context.width * 0.05),
          child: AppButton.small(
            onTap: button2.onTap,
            label: button2.label,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size(Get.width * 0.5, 60),
        child: Obx(
          () {
            if (kVariant == Variant.development) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
              child: Row(
                children: Variant.variants
                    .map(
                      (e) => Flexible(
                        child: RadioListTile<Variant>(
                          value: e,
                          title: Text(e.appName ?? ''),
                          groupValue: kVariant,
                          onChanged: (value) {
                            kVariant = value ?? Variant.variant1;
                            setGeminiApiKey();
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
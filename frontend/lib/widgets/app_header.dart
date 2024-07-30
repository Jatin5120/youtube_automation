import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.label,
    this.button1,
    this.button2,
    this.button3,
  });

  final String label;
  final NavButtonWrapper? button1;
  final NavButtonWrapper? button2;
  final NavButtonWrapper? button3;

  @override
  Size get preferredSize => Size(Get.width, 60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(label),
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.backgroundDark,
      actions: [
        if (button1 != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton.small(
              onTap: button1!.onTap,
              label: button1!.label,
            ),
          ),
        ],
        if (button2 != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton.small(
              onTap: button2!.onTap,
              label: button2!.label,
            ),
          ),
        ],
        if (button3 != null) ...[
          Padding(
            padding: EdgeInsets.only(right: context.width * 0.05),
            child: AppButton.small(
              onTap: button3!.onTap,
              label: button3!.label,
            ),
          ),
        ],
      ],
    );
  }
}

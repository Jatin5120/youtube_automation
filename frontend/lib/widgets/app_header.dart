import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.label,
    required this.buttons,
  });

  final String label;
  final List<NavButtonWrapper> buttons;

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
        for (var i = 0; i < buttons.length; i++) ...[
          Padding(
            padding: EdgeInsets.only(
              right: i == buttons.length - 1 ? context.width * 0.05 : 16,
            ),
            child: AppButton.small(
              onTap: buttons[i].onTap,
              label: buttons[i].label,
              color: AppColors.cardDark,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

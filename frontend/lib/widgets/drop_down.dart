import 'package:flutter/material.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class AppDropDown<T> extends StatelessWidget {
  const AppDropDown({
    super.key,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
    required this.value,
    required this.items,
    this.labelBuilder,
    this.itemBuilder,
    this.selectedItemBuilder,
  });

  final String? label;
  final String? hint;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;
  final List<T> items;
  final String Function(T)? labelBuilder;
  final Widget Function(T)? itemBuilder;
  final Widget Function(T)? selectedItemBuilder;
  final T? value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            AppText(
              label ?? '',
              style: context.textTheme.bodyMedium?.withTitleColor,
            ),
            const SizedBox(height: 6),
          ],
          DropdownButtonFormField<T>(
            items: items
                .map(
                  (e) => DropdownMenuItem<T>(
                    value: e,
                    alignment: Alignment.centerLeft,
                    child: itemBuilder?.call(e) ??
                        AppText(
                          labelBuilder?.call(e) ?? e.toString(),
                        ),
                  ),
                )
                .toList(),
            selectedItemBuilder: (_) => items
                .map(
                  (e) =>
                      selectedItemBuilder?.call(e) ??
                      itemBuilder?.call(e) ??
                      AppText(
                        labelBuilder?.call(e) ?? e.toString(),
                      ),
                )
                .toList(),
            isDense: true,
            initialValue: value,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onChanged: onChanged,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              floatingLabelStyle: context.textTheme.bodyMedium?.withBodyColor,
              alignLabelWithHint: true,
              isDense: true,
            ),
            style: context.textTheme.bodyMedium?.withTitleColor,
          ),
        ],
      );
}

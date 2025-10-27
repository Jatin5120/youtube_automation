import 'package:flutter/material.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.maxLength,
    this.onFieldSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofillHints,
    this.onChanged,
    this.obscureText = false,
    this.suffixIcon,
  })  : assert(minLines > 0, 'minLines cannot be less than 1'),
        assert(maxLines > 0, 'maxLines cannot be less than 1'),
        assert(maxLines >= minLines, 'maxLines cannot be less than minLines');

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final bool obscureText;
  final Widget? suffixIcon;

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
          TextFormField(
            controller: controller,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            minLines: minLines,
            maxLines: maxLines,
            maxLength: maxLength,
            autofillHints: autofillHints,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: context.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              floatingLabelStyle: context.textTheme.bodyMedium?.withBodyColor,
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixIcon: suffixIcon,
            ),
            onFieldSubmitted: onFieldSubmitted,
            style: context.textTheme.bodyMedium?.withTitleColor,
            onChanged: onChanged,
          ),
        ],
      );
}

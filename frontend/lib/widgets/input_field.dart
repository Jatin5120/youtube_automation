import 'package:flutter/material.dart';
import 'package:frontend/utils/utils.dart';
import 'package:get/get.dart';

class InputField extends StatelessWidget {
  const InputField({
    super.key,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.maxLength,
    this.onFieldSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofillHints,
  })  : assert(minLines > 0, 'minLines cannot be less than 1'),
        assert(maxLines > 0, 'maxLines cannot be less than 1'),
        assert(maxLines >= minLines, 'maxLines cannot be less than minLines');

  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int minLines;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.textTheme.bodyLarge?.copyWith(
          color: Colors.grey,
        ),
        alignLabelWithHint: true,
      ),
      onFieldSubmitted: onFieldSubmitted,
      style: context.textTheme.bodyLarge?.withBodyColor,
    );
  }
}

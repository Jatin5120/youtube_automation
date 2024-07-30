import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:frontend/widgets/widgets.dart';
import 'package:get/get.dart';

class MessageContent extends StatelessWidget {
  const MessageContent({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final void Function(String)? onChanged;

  void _insertTextAtCursorPosition(String newText) {
    final text = controller.text;
    final selection = controller.selection;

    final newTextValue = text.replaceRange(selection.start, selection.end, newText);
    final newCursorPosition = selection.start + newText.length;

    controller.value = TextEditingValue(
      text: newTextValue,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    FocusManager.instance.primaryFocus?.unfocus();
    onChanged?.call(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.titleLarge?.withTitleColor,
        ),
        const SizedBox(height: 8),
        InputField(
          controller: controller,
          hint: 'Enter your $label template',
          minLines: 8,
          maxLines: 10,
          onChanged: onChanged,
        ),
        // const SizedBox(height: 8),
        // Wrap(
        //   spacing: 10,
        //   runSpacing: 10,
        //   children: ContentItem.remainingValues(controller.text)
        //       .map(
        //         (e) => _InsertContent(
        //           e,
        //           controller: controller,
        //           onTap: () => _insertTextAtCursorPosition(e.text),
        //         ),
        //       )
        //       .toList(),
        // ),
      ],
    );
  }
}

class _InsertContent extends StatelessWidget {
  const _InsertContent(
    this.content, {
    required this.controller,
    this.onTap,
  });

  final ContentItem content;
  final TextEditingController controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapHandler(
      showSplash: false,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            content.name,
            style: context.textTheme.titleSmall?.withBodyColor,
          ),
        ),
      ),
    );
  }
}

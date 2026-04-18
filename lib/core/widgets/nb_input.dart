import 'package:flutter/material.dart';
import '../theme/neubrut_tokens.dart';

/// NBInput — white fill, 2 px black border, strong focus state (3 px border).
class NBInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? label;
  final IconData? prefixIcon;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final bool autofocus;
  final int? maxLines;

  const NBInput({
    super.key,
    this.controller,
    this.hintText,
    this.label,
    this.prefixIcon,
    this.onSubmitted,
    this.textInputAction,
    this.style,
    this.autofocus = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: NBText.label),
          const SizedBox(height: NBSpacing.xs),
        ],
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          style: style ?? NBText.body,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: NBColors.black, size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class SegmentedCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final Function(String) onChanged;
  final double height;
  final double fontSize;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsets padding;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;

  const SegmentedCodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onChanged,
    this.height = 44,
    this.fontSize = 20,
    this.borderColor = CupertinoColors.systemGrey4,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Stack(
        children: [
          Row(
            children: List.generate(
              length,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: index == 0 || index == length - 1 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                    ),
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: CupertinoColors.white,
                  ),
                  alignment: Alignment.center,
                  height: height,
                  child: Text(
                    index < controller.text.length
                        ? controller.text[index]
                        : '',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          CupertinoTextField(
            controller: controller,
            focusNode: focusNode,
            maxLength: length,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            showCursor: false,
            inputFormatters: keyboardType == TextInputType.number 
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.withOpacity(0),
            ),
            style: TextStyle(
              color: CupertinoColors.systemBackground.withOpacity(0),
              height: 0,
            ),
          ),
        ],
      ),
    );
  }
}

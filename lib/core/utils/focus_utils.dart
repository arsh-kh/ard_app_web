import 'package:flutter/material.dart';

/// A custom FocusNode that automatically selects all text in a TextField
/// when it gains focus for the first time. This solves the issue of having
/// to double tap or manually select all text to replace the entire input.
class SelectAllFocusNode extends FocusNode {
  final TextEditingController controller;

  SelectAllFocusNode({required this.controller}) {
    addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (hasFocus) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    removeListener(_handleFocusChange);
    super.dispose();
  }
}

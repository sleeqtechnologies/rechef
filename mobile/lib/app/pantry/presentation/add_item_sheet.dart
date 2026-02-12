import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for adding pantry items. Frosted glass style; text field at
/// top for comma-separated ingredients; submit via keyboard checkmark.
class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  /// Parses comma-separated input into trimmed non-empty ingredient names.
  static List<String> parseIngredients(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const double _sheetRadius = 20;
  static const double _blurSigma = 12;

  @override
  void initState() {
    super.initState();
    // Automatically focus the input when the sheet appears so the keyboard
    // opens without an extra tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final ingredients = AddItemSheet.parseIngredients(_controller.text);
    Navigator.of(context).pop(ingredients);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(_sheetRadius),
        topRight: Radius.circular(_sheetRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_sheetRadius),
              topRight: Radius.circular(_sheetRadius),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Text field (no border)
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'pantry.add_hint'.tr(),
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

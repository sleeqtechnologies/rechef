import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass bottom sheet for entering a recipe URL.
/// Returns the trimmed URL string when the user taps Done on the keyboard.
class ImportUrlSheet extends StatefulWidget {
  const ImportUrlSheet({super.key});

  @override
  State<ImportUrlSheet> createState() => _ImportUrlSheetState();
}

class _ImportUrlSheetState extends State<ImportUrlSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const double _sheetRadius = 20;
  static const double _blurSigma = 12;

  @override
  void initState() {
    super.initState();
    // Automatically focus the URL field when the sheet opens so the keyboard
    // appears without requiring an extra tap.
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
    final url = _controller.text.trim();
    if (url.isNotEmpty) {
      Navigator.of(context).pop(url);
    }
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
                  // Drag handle
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
                  // URL text field (no border)
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Paste recipe URL here...',
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
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    maxLines: 1,
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

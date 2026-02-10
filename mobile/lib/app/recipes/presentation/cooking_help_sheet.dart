import 'dart:convert';
import 'dart:math' show min;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../recipe_provider.dart';


class CookingHelpSheet extends ConsumerStatefulWidget {
  const CookingHelpSheet({
    super.key,
    required this.recipeId,
    required this.currentStep,
  });

  final String recipeId;
  final int currentStep;

  static Future<void> show(
    BuildContext context, {
    required String recipeId,
    required int currentStep,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookingHelpSheet(
        recipeId: recipeId,
        currentStep: currentStep,
      ),
    );
  }

  @override
  ConsumerState<CookingHelpSheet> createState() => _CookingHelpSheetState();
}

class _CookingHelpSheetState extends ConsumerState<CookingHelpSheet> {
  late final InMemoryChatController _chatController;
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  static const _currentUserId = 'user';
  static const _assistantId = 'assistant';
  static const _accentColor = Color(0xFFFF4F63);

  bool _loading = false;
  bool _sending = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chatController = InMemoryChatController();
    _loadHistory();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final messages = await repo.fetchChatHistory(widget.recipeId);
      for (final msg in messages) {
        final role = msg['role'] as String;
        final authorId = role == 'user' ? _currentUserId : _assistantId;
        final id = msg['id'] as String;
        final content = msg['content'] as String;
        final createdAt = DateTime.tryParse(msg['createdAt'] as String? ?? '');
        final imageBase64 = msg['imageBase64'] as String?;

        if (imageBase64 != null && imageBase64.isNotEmpty) {
          await _chatController.insertMessage(
            Message.image(
              id: id,
              authorId: authorId,
              source: imageBase64,
              text: content,
              createdAt: createdAt,
            ),
          );
        } else {
          await _chatController.insertMessage(
            Message.text(
              id: id,
              authorId: authorId,
              text: content,
              createdAt: createdAt,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage(String text, {String? imageBase64}) async {
    if (text.trim().isEmpty && imageBase64 == null) return;
    if (_sending) return;

    setState(() => _sending = true);

    final userMsgId = 'local-${DateTime.now().millisecondsSinceEpoch}';

    // Optimistically add user message
    if (imageBase64 != null) {
      await _chatController.insertMessage(
        Message.image(
          id: userMsgId,
          authorId: _currentUserId,
          source: imageBase64,
          text: text.trim(),
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await _chatController.insertMessage(
        Message.text(
          id: userMsgId,
          authorId: _currentUserId,
          text: text.trim(),
          createdAt: DateTime.now(),
        ),
      );
    }

    _textController.clear();

    try {
      final repo = ref.read(recipeRepositoryProvider);
      String accumulatedText = '';
      Message? streamingMsg;
      final streamingMsgId =
          'streaming-${DateTime.now().millisecondsSinceEpoch}';
      final streamingCreatedAt = DateTime.now();

      await for (final event in repo.sendChatMessageStream(
        widget.recipeId,
        message: text.trim(),
        imageBase64: imageBase64,
        currentStep: widget.currentStep,
      )) {
        if (!mounted) break;

        final eventType = event['_event'] as String;

        if (eventType == 'userMessage') {
          // Replace local user message with server one
          try {
            final localMsg = _chatController.messages.firstWhere(
              (m) => m.id == userMsgId,
            );
            await _chatController.removeMessage(localMsg);
            if (event['imageBase64'] != null) {
              await _chatController.insertMessage(
                Message.image(
                  id: event['id'] as String,
                  authorId: _currentUserId,
                  source: event['imageBase64'] as String,
                  text: event['content'] as String?,
                  createdAt:
                      DateTime.tryParse(event['createdAt'] as String? ?? ''),
                ),
              );
            } else {
              await _chatController.insertMessage(
                Message.text(
                  id: event['id'] as String,
                  authorId: _currentUserId,
                  text: event['content'] as String,
                  createdAt:
                      DateTime.tryParse(event['createdAt'] as String? ?? ''),
                ),
              );
            }
          } catch (_) {}
        } else if (eventType == 'chunk') {
          accumulatedText += event['text'] as String;
          final newMsg = Message.text(
            id: streamingMsgId,
            authorId: _assistantId,
            text: accumulatedText,
            createdAt: streamingCreatedAt,
          );

          if (streamingMsg == null) {
            await _chatController.insertMessage(newMsg);
          } else {
            await _chatController.updateMessage(streamingMsg, newMsg);
          }
          streamingMsg = newMsg;
        } else if (eventType == 'done') {
          final assistant =
              event['assistantMessage'] as Map<String, dynamic>;
          final finalMsg = Message.text(
            id: assistant['id'] as String,
            authorId: _assistantId,
            text: assistant['content'] as String,
            createdAt:
                DateTime.tryParse(assistant['createdAt'] as String? ?? ''),
          );

          if (streamingMsg != null) {
            await _chatController.updateMessage(streamingMsg, finalMsg);
          } else {
            await _chatController.insertMessage(finalMsg);
          }
        } else if (eventType == 'error') {
          throw Exception(event['error'] as String? ?? 'Unknown error');
        }
      }
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Voice ─────────────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (!available) return;

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        _textController.text = result.recognizedWords;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      },
    );
  }

  // ── Image ─────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64 = base64Encode(bytes);
    final dataUrl = 'data:image/jpeg;base64,$base64';

    // Send with current text or a default message
    final text = _textController.text.trim().isNotEmpty
        ? _textController.text.trim()
        : 'How does this look?';

    await _sendMessage(text, imageBase64: dataUrl);
  }

  // ── Build ─────────────────────────────────────────────────────────

  static const double _sheetRadius = 20;
  static const double _blurSigma = 12;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final sheetHeight = min(
      mq.size.height * 0.85,
      mq.size.height - keyboardHeight - mq.padding.top,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_sheetRadius),
          topRight: Radius.circular(_sheetRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            height: sheetHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_sheetRadius),
                topRight: Radius.circular(_sheetRadius),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                      child: _loading
                          ? const Center(child: CupertinoActivityIndicator())
                          : Chat(
                              chatController: _chatController,
                              currentUserId: _currentUserId,
                              resolveUser: _resolveUser,
                              onMessageSend: _onMessageSend,
                              backgroundColor: Colors.transparent,
                              theme: ChatTheme.light().copyWith(
                                colors: ChatColors.light().copyWith(
                                  primary: _accentColor,
                                  surface: Colors.transparent,
                                ),
                              ),
                              builders: Builders(
                                composerBuilder: (_) =>
                                    const SizedBox.shrink(),
                                emptyChatListBuilder: _buildEmptyState,
                                textMessageBuilder:
                                    _buildMarkdownTextMessage,
                              ),
                            ),
                    ),
                _buildComposer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final suggestions = [
      'What can I substitute for an ingredient I don\'t have?',
      'How do I know when this is done cooking?',
      'Can I make this recipe ahead of time?',
      'What sides go well with this dish?',
      'How do I adjust this for more servings?',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/ai.svg',
              width: 36,
              height: 36,
              colorFilter: ColorFilter.mode(
                Colors.grey.shade400,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI cooking assistant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try asking:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                return GestureDetector(
                  onTap: () => _sendMessage(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatMessageTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildMarkdownTextMessage(
    BuildContext context,
    TextMessage message,
    int index, {
    required bool isSentByMe,
    MessageGroupStatus? groupStatus,
  }) {
    final textColor = isSentByMe ? Colors.white : Colors.grey.shade800;
    final backgroundColor = isSentByMe
        ? _accentColor
        : Colors.grey.shade100;
    final baseStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      height: 1.35,
    );
    final styleSheet = MarkdownStyleSheet(
      p: baseStyle,
      listBullet: baseStyle,
      h1: baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      h2: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      h3: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      strong: baseStyle.copyWith(fontWeight: FontWeight.w600),
      blockquote: baseStyle.copyWith(color: textColor.withOpacity(0.9)),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: textColor, width: 3)),
      ),
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: textColor.withOpacity(0.1),
      ),
      codeblockDecoration: BoxDecoration(
        color: textColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: backgroundColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message.text,
              styleSheet: styleSheet,
              shrinkWrap: true,
              fitContent: true,
            ),
            const SizedBox(height: 4),
            if (message.resolvedTime != null)
              Text(
                _formatMessageTime(message.resolvedTime!),
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Chat callbacks ────────────────────────────────────────────────

  Future<User> _resolveUser(String userId) async {
    if (userId == _assistantId) {
      return const User(id: _assistantId, name: 'Chef AI');
    }
    return const User(id: _currentUserId, name: 'You');
  }

  void _onMessageSend(String text) {
    _sendMessage(text);
  }

  // ── Custom composer ───────────────────────────────────────────────

  Widget _buildComposer(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            // Camera button
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Mic button
            GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? _accentColor.withOpacity(0.15)
                      : Colors.grey.shade100,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 18,
                  color: _isListening ? _accentColor : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) _sendMessage(text);
                },
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : 'Ask anything...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: () {
                if (_textController.text.trim().isNotEmpty) {
                  _sendMessage(_textController.text);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor,
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// faq_page.dart — Customer Support Chatbot Screen
// ============================================================
// Displays a real-time AI chatbot interface where customers
// can type any question or pick from pre-loaded FAQ shortcuts.
//
// Integration (see FRONTEND_INTEGRATION.md):
//   All messages are sent to the chatbot server via
//   ChatbotService.ask(). That service handles the two-step
//   flow automatically:
//     1. POST /chat       → get answer or data_needed
//     2. POST /chat/respond → send local DB data, get answer
//
// UI behaviour:
//   • User types a question in the bottom input bar and taps
//     the send button (or presses Enter).
//   • A "typing…" indicator appears while waiting for the API.
//   • Bot replies are rendered as formatted Markdown so bold,
//     lists, tables, and headings display correctly.
//   • The "Browse FAQ" icon opens a bottom sheet of pre-defined
//     questions from the local database. Tapping one sends it.
//   • The "New Chat" icon clears the local message history and
//     resets the server-side session so the next question starts
//     a fresh conversation with no prior context.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';
import 'package:alis_grandson_app/src/core/database/database_helper.dart';
import 'package:alis_grandson_app/src/shared/services/chatbot_service.dart';

/// Chat-style AI support screen for customers.
class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // ── State ──────────────────────────────────────────────────

  /// Chat history. Role is "user", "bot", or "typing".
  /// "typing" renders the animated dots placeholder.
  final List<Map<String, String>> _messages = [
    {
      'role': 'bot',
      'text':
          'Hello! I\'m the Ali Grandson assistant. Type your question below '
              'or tap the **FAQ** icon to browse common topics.',
    }
  ];

  List<Map<String, dynamic>> _faqs = [];
  String? _username;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  bool _isSending = false;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadFAQs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('user_username'));
  }

  Future<void> _loadFAQs() async {
    final faqs = await DatabaseHelper.instance.getAllFAQs();
    setState(() => _faqs = faqs);
  }

  // ── Sending a message ──────────────────────────────────────

  Future<void> _sendMessage() async {
    final question = _inputController.text.trim();
    if (question.isEmpty || _isSending) return;

    _inputController.clear();
    _inputFocus.unfocus();

    setState(() {
      _isSending = true;
      _messages.add({'role': 'user', 'text': question});
      _messages.add({'role': 'typing', 'text': ''});
    });
    _scrollToBottom();

    final answer = await ChatbotService.ask(question, username: _username);

    setState(() {
      final idx = _messages.lastIndexWhere((m) => m['role'] == 'typing');
      if (idx != -1) _messages[idx] = {'role': 'bot', 'text': answer};
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── New Chat ───────────────────────────────────────────────

  void _newChat() {
    // Reset the server-side session so no previous context bleeds in.
    ChatbotService.resetSession();

    setState(() {
      _messages
        ..clear()
        ..add({
          'role': 'bot',
          'text':
              'Hello! I\'m the Ali Grandson assistant. Type your question below '
                  'or tap the **FAQ** icon to browse common topics.',
        });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New conversation started.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── FAQ picker ─────────────────────────────────────────────

  void _showFaqPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kGreyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Browse Common Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a question to ask it',
                style: TextStyle(fontSize: 13, color: kGreyMedium),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: kGreyLight),
              Expanded(
                child: _faqs.isEmpty
                    ? const Center(
                        child: Text(
                          'No common questions found.',
                          style: TextStyle(color: kGreyMedium),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _faqs.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: kGreyLight),
                        itemBuilder: (context, index) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 4,
                          ),
                          leading: const Icon(
                            Icons.help_outline_rounded,
                            color: kPrimaryColor,
                            size: 20,
                          ),
                          title: Text(
                            _faqs[index]['question']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: kGreyMedium,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _inputController.text = _faqs[index]['question']!;
                            _sendMessage();
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // resizeToAvoidBottomInset (default true) shrinks the body when
    // the keyboard opens, so the input bar stays at the bottom
    // naturally — no manual viewInsets padding needed.
    return Scaffold(
      backgroundColor: kBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('SUPPORT CENTER'),
        backgroundColor: kSurfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            tooltip: 'Browse FAQ',
            onPressed: _showFaqPicker,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: _isSending ? null : _newChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Chat list ──────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['role'] == 'typing') return _buildTypingIndicator();
                return _buildChatBubble(
                  msg['text']!,
                  isBot: msg['role'] == 'bot',
                );
              },
            ),
          ),

          // ── Input bar (keyboard-aware) ─────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Widget builders ────────────────────────────────────────

  Widget _buildChatBubble(String text, {required bool isBot}) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: isBot ? kSurfaceColor : kPrimaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isBot ? 4 : 20),
            bottomRight: Radius.circular(isBot ? 20 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // Bot messages are rendered as Markdown; user messages are
        // plain text (the user types plain text, not markdown).
        child: isBot
            ? MarkdownBody(
                data: text,
                shrinkWrap: true,
                softLineBreak: true,
                styleSheet: _botMarkdownStyle(),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
      ),
    );
  }

  /// Markdown style sheet that matches the bot bubble's white/light surface.
  MarkdownStyleSheet _botMarkdownStyle() {
    const bodyColor = kSecondaryColor;
    const bodySize = 15.0;
    const bodyHeight = 1.45;

    return MarkdownStyleSheet(
      p: const TextStyle(
          color: bodyColor, fontSize: bodySize, height: bodyHeight),
      strong: const TextStyle(
          color: bodyColor,
          fontSize: bodySize,
          fontWeight: FontWeight.bold,
          height: bodyHeight),
      em: const TextStyle(
          color: bodyColor,
          fontSize: bodySize,
          fontStyle: FontStyle.italic,
          height: bodyHeight),
      h1: const TextStyle(
          color: bodyColor, fontSize: 18, fontWeight: FontWeight.bold),
      h2: const TextStyle(
          color: bodyColor, fontSize: 16, fontWeight: FontWeight.bold),
      h3: const TextStyle(
          color: bodyColor, fontSize: 15, fontWeight: FontWeight.w600),
      listBullet: const TextStyle(color: bodyColor, fontSize: bodySize),
      blockquote: TextStyle(
          color: kGreyMedium, fontSize: 14, fontStyle: FontStyle.italic),
      code: const TextStyle(
        color: kPrimaryColor,
        backgroundColor: kBackgroundColor,
        fontSize: 13,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      tableHead: const TextStyle(
          color: bodyColor, fontWeight: FontWeight.bold, fontSize: 13),
      tableBody:
          const TextStyle(color: bodyColor, fontSize: 13, height: 1.4),
      tableBorder: TableBorder.all(color: kGreyLight, width: 1),
      tableCellsPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      blockSpacing: 8,
      listIndent: 16,
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const _TypingDots(),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false, // only apply bottom safe area inset
      child: Container(
        color: kSurfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Browse FAQ button ──────────────────────────
            IconButton(
              icon:
                  const Icon(Icons.help_outline_rounded, color: kPrimaryColor),
              tooltip: 'Browse FAQ',
              onPressed: _showFaqPicker,
            ),

            // ── Text input ─────────────────────────────────
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  enabled: !_isSending,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  maxLines: null, // grows with content up to maxHeight
                  decoration: InputDecoration(
                    hintText: 'Ask anything…',
                    hintStyle: TextStyle(color: kGreyMedium, fontSize: 14),
                    filled: true,
                    fillColor: kBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // ── Send button ────────────────────────────────
            _isSending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: kPrimaryColor),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: kPrimaryColor,
                    iconSize: 26,
                    onPressed: _sendMessage,
                    tooltip: 'Send',
                  ),
          ],
        ),
      ),
    );
  }
}

// ── Typing animation ────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_controller.value - i * 0.3).clamp(0.0, 1.0);
          final opacity =
              (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.3, 1.0);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha:opacity),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

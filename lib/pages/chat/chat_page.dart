import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_ChatMessage.dart';
import '_ChatInput.dart';
import '_TranslationBanner.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  bool _autoTranslate = true;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: 'مرحباً، أنا في طريقي، سأكون هناك خلال 5 دقائق.',
      translatedText: "Hello, I'm on my way. I'll be there in 5 minutes.",
      isMe: false,
      time: '2:41 PM',
      isArabic: true,
    ),
    ChatMessage(
      id: '2',
      text: "Great, thanks! I'm waiting near the main entrance.",
      isMe: true,
      time: '2:43 PM',
    ),
    ChatMessage(
      id: '3',
      text: 'حسناً، أراك قريباً.',
      translatedText: 'Okay, see you soon.',
      isMe: false,
      time: '2:44 PM',
      isArabic: true,
    ),
    ChatMessage(
      id: '4',
      text: 'وصلت إلى المدخل الرئيسي.',
      translatedText: "I'll arrive at the main entrance.",
      isMe: false,
      time: '2:45 PM',
      isArabic: true,
    ),
  ];

  // ── Delete ──────────────────────────────────────────────
  void _deleteMessage(String id) {
    setState(() => _messages.removeWhere((m) => m.id == id));
  }

  // ── Edit ────────────────────────────────────────────────
  void _editMessage(String id, String newText) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          text: newText,
          isEdited: true,
        );
      }
    });
  }

  // ── Send text ───────────────────────────────────────────
  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isMe: true,
        time: _formatTime(DateTime.now()),
      ));
    });
    _input.clear();
    _scrollToBottom();
  }

  // ── Send voice ──────────────────────────────────────────
  void _sendVoice(String audioPath) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '🎤 Voice message',
        isMe: true,
        time: _formatTime(DateTime.now()),
        isVoice: true,
        audioPath: audioPath, // real file path
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _ChatTopBar(),
            TranslationBanner(
              enabled: _autoTranslate,
              onToggle: (v) => setState(() => _autoTranslate = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Today, 2:41 PM',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.subtext(context),
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages',
                        style: AppTextStyles.bodySmall(context)
                            .copyWith(color: AppColors.subtext(context)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        return ChatBubble(
                          message: msg,
                          showTranslation: _autoTranslate,
                          onDelete: () => _deleteMessage(msg.id),
                          onEdit: (newText) => _editMessage(msg.id, newText),
                        );
                      },
                    ),
            ),
            ChatInputBar(
              controller: _input,
              onSend: _sendMessage,
              onVoiceSend: _sendVoice, // <-- wired here
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryPurple.withOpacity(0.15),
            child: Icon(Icons.person_rounded,
                color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ahmed H.',
                    style: AppTextStyles.bodyMedium(context)
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('Toyota Camry · 4.9 ★',
                    style: AppTextStyles.bodySmall(context)
                        .copyWith(color: AppColors.subtext(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
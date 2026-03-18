import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '_VoiceMessageBubble.dart';

class ChatMessage {
  final String id;
  final String text;
  final String? translatedText;
  final bool isMe;
  final String time;
  final bool isArabic;
  final bool isVoice;
  final bool isEdited;

  /// For voice messages: the local file path returned by the recorder.
  final String? audioPath;

  const ChatMessage({
    required this.id,
    required this.text,
    this.translatedText,
    required this.isMe,
    required this.time,
    this.isArabic = false,
    this.isVoice = false,
    this.isEdited = false,
    this.audioPath,
  });

  ChatMessage copyWith({
    String? text,
    String? translatedText,
    bool? isEdited,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      translatedText: translatedText ?? this.translatedText,
      isMe: isMe,
      time: time,
      isArabic: isArabic,
      isVoice: isVoice,
      isEdited: isEdited ?? this.isEdited,
      audioPath: audioPath,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatBubble
// ─────────────────────────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTranslation;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onEdit;

  const ChatBubble({
    super.key,
    required this.message,
    this.showTranslation = true,
    this.onDelete,
    this.onEdit,
  });

  void _showActionSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageActionsSheet(
        message: message,
        onDelete: onDelete,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Voice bubble ───────────────────────────────────────
    if (message.isVoice) {
      return GestureDetector(
        onLongPress: () => _showActionSheet(context),
        child: VoiceMessageBubble(
          isMe: message.isMe,
          time: message.time,
          audioPath: message.audioPath,
        ),
      );
    }

    // ── Text bubble ────────────────────────────────────────
    final isMe = message.isMe;
    final bubbleColor =
        isMe ? AppColors.primaryPurple : AppColors.surface(context);
    final textColor = isMe ? Colors.white : AppColors.text(context);

    return GestureDetector(
      onLongPress: () => _showActionSheet(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
              if (showTranslation && message.translatedText != null) ...[
                const SizedBox(height: 6),
                Divider(color: textColor.withOpacity(0.2), height: 1),
                const SizedBox(height: 6),
                Text(
                  message.translatedText!,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: textColor.withOpacity(0.75),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (message.isEdited)
                    Text(
                      'edited · ',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 10,
                        color: textColor.withOpacity(0.45),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Text(
                    message.time,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 10,
                      color: textColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action sheet: Edit + Delete
// ─────────────────────────────────────────────────────────────────────────────
class _MessageActionsSheet extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onEdit;

  const _MessageActionsSheet({
    required this.message,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.subtext(context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (message.isMe && !message.isVoice) ...[
            _ActionTile(
              icon: Icons.edit_rounded,
              label: 'Edit',
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
            ),
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: AppColors.subtext(context).withOpacity(0.15),
            ),
          ],
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(
            hintText: 'Edit your message…',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.primaryPurple, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.subtext(context))),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != message.text) {
                onEdit?.call(newText);
              }
              Navigator.pop(ctx);
            },
            child: Text('Save',
                style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete message?'),
        content: const Text('This message will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.subtext(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppColors.text(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: color,
                  fontSize: 15,
                  fontWeight: isDestructive
                      ? FontWeight.w600
                      : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
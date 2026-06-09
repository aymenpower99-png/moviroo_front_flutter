import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../services/support_service.dart';

class MessagesModal extends StatefulWidget {
  final List<SupportTicket> initialTickets;
  final Function(SupportTicket) onTicketTap;

  const MessagesModal({
    super.key,
    required this.initialTickets,
    required this.onTicketTap,
  });

  @override
  State<MessagesModal> createState() => _MessagesModalState();
}

class _MessagesModalState extends State<MessagesModal> {
  final SupportService _supportService = SupportService();
  List<SupportTicket> _tickets = [];
  bool _isRefreshing = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _tickets = List.from(widget.initialTickets);
    _loadTickets();
    // Rebuild periodically so relative timestamps update (same as driver app)
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _isRefreshing = true);
    try {
      final fresh = await _supportService.listTickets();
      if (mounted) {
        setState(() {
          _tickets = fresh;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _handleTap(SupportTicket ticket) {
    widget.onTicketTap(ticket);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate('messages'),
                    style: AppTextStyles.pageTitle(
                      context,
                    ).copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_isRefreshing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple,
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppColors.border(context).withValues(alpha: 0.5),
          ),
          // Content
          Expanded(
            child: _tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.forum_outlined,
                            color: AppColors.primaryPurple.withValues(
                              alpha: 0.5,
                            ),
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).translate('no_messages_yet'),
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.subtext(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      final unread = ticket.hasUnread;
                      return _TicketThreadItem(
                        ticket: ticket,
                        unread: unread,
                        onTap: () => _handleTap(ticket),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TicketThreadItem extends StatelessWidget {
  final SupportTicket ticket;
  final bool unread;
  final VoidCallback onTap;

  const _TicketThreadItem({
    required this.ticket,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: unread
              ? AppColors.primaryPurple.withValues(alpha: isDark ? 0.12 : 0.05)
              : AppColors.bg(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unread
                ? AppColors.primaryPurple.withValues(alpha: 0.2)
                : AppColors.border(context).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Unread dot indicator — left edge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: unread ? AppColors.primaryPurple : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: AppColors.primaryPurple,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            // Subject + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('customer_support'),
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      color: unread
                          ? AppColors.text(context)
                          : AppColors.text(context).withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ticket.lastMessage ?? ticket.description,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: unread
                          ? AppColors.text(context).withValues(alpha: 0.65)
                          : AppColors.subtext(context),
                      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

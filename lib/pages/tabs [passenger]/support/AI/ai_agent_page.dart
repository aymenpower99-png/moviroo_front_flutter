import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import 'ai_widgets.dart';

class AiAgentPage extends StatefulWidget {
  const AiAgentPage({super.key});

  @override
  State<AiAgentPage> createState() => _AiAgentPageState();
}

class _AiAgentPageState extends State<AiAgentPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCardTap(String query) {
    setState(() {
      _controller.text = query;
    });
    _focusNode.requestFocus();
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    
    final message = _controller.text;
    debugPrint('Sending message: $message');
    
    // TODO: Implement your AI message handling here
    // Example: context.read<AiChatProvider>().sendMessage(message);
    
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const AiHeader(),
            
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const AiHeroSection(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: AiActionCards(onCardTap: _handleCardTap),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            
            // Input section
            AiInputSection(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}
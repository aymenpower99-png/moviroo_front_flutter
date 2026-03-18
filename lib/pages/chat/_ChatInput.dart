import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final ValueChanged<String> onVoiceSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoiceSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _currentPath;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderReady = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    setState(() => _recorderReady = true);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordTimer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_recorderReady) return;

    // Request mic permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _currentPath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    await _recorder.stopRecorder();
    if (mounted) setState(() => _isRecording = false);

    if (_currentPath != null && _currentPath!.isNotEmpty) {
      widget.onVoiceSend(_currentPath!);
      _currentPath = null;
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stopRecorder();
    _currentPath = null;
    if (mounted) setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  String _fmtSeconds(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: _isRecording
                  ? SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          _PulseDot(),
                          const SizedBox(width: 8),
                          Text(
                            'Recording  ${_fmtSeconds(_recordSeconds)}',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _cancelRecording,
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                fontSize: 13,
                                color: AppColors.subtext(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: widget.controller,
                      style: AppTextStyles.bodyMedium(context)
                          .copyWith(fontSize: 14),
                      maxLines: null,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: AppTextStyles.bodySmall(context)
                            .copyWith(color: AppColors.subtext(context)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _hasText
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: () => widget.onSend(widget.controller.text),
                    child: _ActionButton(
                      color: AppColors.primaryPurple,
                      icon: Icons.send_rounded,
                    ),
                  )
                : _isRecording
                    ? GestureDetector(
                        key: const ValueKey('stop'),
                        onTap: _stopRecording,
                        child: const _ActionButton(
                          color: Colors.red,
                          icon: Icons.stop_rounded,
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey('mic'),
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        onTap: _startRecording,
                        child: _ActionButton(
                          color: AppColors.primaryPurple,
                          icon: Icons.mic_rounded,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
            color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _ActionButton({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
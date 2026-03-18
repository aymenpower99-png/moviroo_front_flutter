import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class VoiceMessageBubble extends StatefulWidget {
  final bool isMe;
  final String time;
  final String? audioPath;

  const VoiceMessageBubble({
    super.key,
    required this.isMe,
    required this.time,
    this.audioPath,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _total = Duration.zero;
  Duration _position = Duration.zero;
  bool _ready = false;
  bool _completed = false; // track if finished playing

  static const List<double> _bars = [
    0.3, 0.6, 0.4, 0.9, 0.5, 0.7, 0.3, 1.0, 0.6, 0.4,
    0.8, 0.5, 0.3, 0.7, 0.9, 0.4, 0.6, 0.3, 0.8, 0.5,
    0.7, 0.4, 0.6, 0.9, 0.3, 0.5, 0.8, 0.4, 0.7, 0.6,
  ];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (widget.audioPath == null) return;
    try {
      // Explicitly no loop
      await _player.setLoopMode(LoopMode.off);
      final duration = await _player.setFilePath(widget.audioPath!);
      if (mounted) setState(() {
        _total = duration ?? Duration.zero;
        _ready = true;
      });

      _player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        if (state.processingState == ProcessingState.completed) {
          // Stop here — do NOT seek, do NOT play again
          _player.stop();
          setState(() {
            _isPlaying = false;
            _completed = true;
            _position = Duration.zero;
          });
        } else {
          setState(() => _isPlaying = state.playing);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_ready) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      // If completed, reload file before playing again
      if (_completed) {
        await _player.setFilePath(widget.audioPath!);
        setState(() => _completed = false);
      }
      await _player.play();
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _total.inMilliseconds > 0
      ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        widget.isMe ? AppColors.primaryPurple : AppColors.surface(context);
    final contentColor =
        widget.isMe ? Colors.white : AppColors.text(context);
    final activeColor =
        widget.isMe ? Colors.white : AppColors.primaryPurple;
    final inactiveColor = widget.isMe
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.subtext(context).withValues(alpha: 0.4);

    final displayTime = _ready && (_isPlaying || _position > Duration.zero)
        ? _fmt(_position)
        : (_ready ? _fmt(_total) : '--:--');

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
            bottomRight: Radius.circular(widget.isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primaryPurple.withValues(alpha: 0.12),
                ),
                child: _ready
                    ? Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: widget.isMe
                            ? Colors.white
                            : AppColors.primaryPurple,
                        size: 22,
                      )
                    : SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.isMe
                              ? Colors.white
                              : AppColors.primaryPurple,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  height: 28,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_bars.length, (i) {
                      final isActive = (i / _bars.length) <= _progress;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 60),
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          height: _bars[i] * 22,
                          decoration: BoxDecoration(
                            color: isActive ? activeColor : inactiveColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      displayTime,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 11,
                        color: contentColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Text(
                      widget.time,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 11,
                        color: contentColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
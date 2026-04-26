import 'package:flutter/material.dart';

class SuccessIcon extends StatefulWidget {
  const SuccessIcon({super.key});

  @override
  State<SuccessIcon> createState() => _SuccessIconState();
}

class _SuccessIconState extends State<SuccessIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _glowAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
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
      builder: (_, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.30 * _glowAnim.value),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: _scaleAnim.value,
              child: Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
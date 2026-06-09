import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../routing/router.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/notification_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  late VideoPlayerController _controller;
  bool _controllerReady = false;

  bool _sessionOk = false;
  bool _videoReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Remove native splash immediately — never block on video init
    FlutterNativeSplash.remove();

    // Run both in parallel; Future.wait ensures session is set before we handle fallback
    final results = await Future.wait([_tryLoadVideo(), _checkSession()]);

    // Wait 2 seconds for splash to display, then navigate regardless of video
    await Future.delayed(const Duration(seconds: 2));
    _goNext();
  }

  // 🎥 VIDEO — returns true if video loaded, false on failure
  Future<bool> _tryLoadVideo() async {
    try {
      _controller = VideoPlayerController.asset('images/appanim.mp4');
      await _controller.initialize().timeout(const Duration(seconds: 5));

      setState(() => _videoReady = true);
      _controllerReady = true;
      _controller
        ..setLooping(false)
        ..play();

      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          _goNext();
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // 🔐 SESSION
  Future<void> _checkSession() async {
    _sessionOk = await _authService.tryRestoreSession();
  }

  void _goNext() async {
    if (!mounted || _navigated) return;

    _navigated = true;

    if (_sessionOk) {
      // User was already logged in — register FCM token
      await NotificationService().registerTokenAfterLogin();
      if (mounted) AppRouter.clearAndGo(context, AppRouter.home);
    } else {
      if (mounted) AppRouter.clearAndGo(context, AppRouter.login);
    }
  }

  @override
  void dispose() {
    if (_controllerReady) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // match your splash design

      body: _videoReady
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox(), // native splash still shows here
    );
  }
}

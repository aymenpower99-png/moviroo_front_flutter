import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../routing/router.dart';
import '../../services/auth_service/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  late VideoPlayerController _controller;

  bool _sessionOk = false;
  bool _videoReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadVideo(),
      _checkSession(),
    ]);
  }

  // 🎥 VIDEO
  Future<void> _loadVideo() async {
    _controller = VideoPlayerController.asset('images/appanim.mp4');

    await _controller.initialize();

    // 🔥 IMPORTANT: REMOVE SPLASH FIRST (no fade)
    FlutterNativeSplash.remove();

    setState(() {
      _videoReady = true;
    });

    _controller
      ..setLooping(false)
      ..play();

    // Navigate when video ends
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        _goNext();
      }
    });
  }

  // 🔐 SESSION
  Future<void> _checkSession() async {
    _sessionOk = await _authService.tryRestoreSession();
  }

  void _goNext() {
    if (!mounted || _navigated) return;

    _navigated = true;

    if (_sessionOk) {
      AppRouter.clearAndGo(context, AppRouter.home);
    } else {
      AppRouter.clearAndGo(context, AppRouter.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
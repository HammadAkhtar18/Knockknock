import 'dart:async';

import 'package:flutter/material.dart';

import '../services/knock_detector_service.dart';
import '../services/response_audio_service.dart';
import 'knock_animation_widget.dart';

class KnockHomePage extends StatefulWidget {
  const KnockHomePage({super.key});

  @override
  State<KnockHomePage> createState() => _KnockHomePageState();
}

class _KnockHomePageState extends State<KnockHomePage> {
  final KnockDetectorService _detector = KnockDetectorService();
  final ResponseAudioService _audioService = ResponseAudioService();
  final GlobalKey<KnockAnimationWidgetState> _animationKey =
      GlobalKey<KnockAnimationWidgetState>();

  @override
  void initState() {
    super.initState();

    _detector.onKnock = _handleKnock;
    _detector.onDoubleKnock = _handleDoubleKnock;

    unawaited(_detector.start());
    unawaited(_audioService.init());
  }

  Future<void> _handleKnock() async {
    final String responseText = await _audioService.playKnockResponse();
    if (!mounted) {
      return;
    }

    _animationKey.currentState?.triggerKnock(responseText);
  }

  Future<void> _handleDoubleKnock() async {
    await _audioService.playDoubleKnockResponse();
    if (!mounted) {
      return;
    }

    _animationKey.currentState?.triggerDoubleKnock();
  }

  @override
  void dispose() {
    _detector.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.settings),
                color: Colors.white,
                onPressed: () {
                  // Placeholder for settings navigation.
                },
              ),
            ),
            Expanded(
              child: KnockAnimationWidget(key: _animationKey),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Text(
                'Knock on your desk 👇',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B949E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

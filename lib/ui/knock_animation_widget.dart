import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class KnockAnimationWidget extends StatefulWidget {
  const KnockAnimationWidget({super.key});

  @override
  KnockAnimationWidgetState createState() => KnockAnimationWidgetState();
}

class KnockAnimationWidgetState extends State<KnockAnimationWidget>
    with TickerProviderStateMixin {
  static const Color _backgroundColor = Color(0xFF0D1117);

  late final AnimationController _shakeController;
  late final AnimationController _scaleController;
  late final AnimationController _bubbleController;

  Animation<double> _shakeAnimation = const AlwaysStoppedAnimation<double>(0);
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _bubbleOpacity;

  bool _isFlashing = false;
  String _bubbleText = '';

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_scaleController);

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _bubbleOpacity = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 200,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 2000,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 200,
      ),
    ]).animate(_bubbleController);
  }

  Future<void> triggerKnock(String responseText) async {
    await _runFlash();
    await _runShake(cycles: 3, aggressive: false);
    await _runScalePulse();
    await _showBubble(responseText);
  }

  Future<void> triggerDoubleKnock() async {
    await _runFlash();
    await _runShake(cycles: 5, aggressive: true);
    await _runScalePulse();
    await _showBubble('SERIOUSLY?! 😤');
  }

  Future<void> _runFlash() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isFlashing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) {
      return;
    }

    setState(() {
      _isFlashing = false;
    });
  }

  Future<void> _runShake({required int cycles, required bool aggressive}) async {
    final double amplitude = aggressive ? 20 : 12;
    _shakeAnimation = _buildShakeAnimation(cycles: cycles, amplitude: amplitude)
        .animate(_shakeController);

    await _shakeController.forward(from: 0);
  }

  Animatable<double> _buildShakeAnimation({
    required int cycles,
    required double amplitude,
  }) {
    final List<double> points = <double>[0];

    for (int i = 0; i < cycles; i++) {
      points
        ..add(-amplitude)
        ..add(amplitude);
    }

    points.add(0);

    final List<TweenSequenceItem<double>> items = <TweenSequenceItem<double>>[];
    for (int i = 0; i < points.length - 1; i++) {
      items.add(
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: points[i], end: points[i + 1]),
          weight: 1,
        ),
      );
    }

    return TweenSequence<double>(items);
  }

  Future<void> _runScalePulse() async {
    await _scaleController.forward(from: 0);
  }

  Future<void> _showBubble(String text) async {
    setState(() {
      _bubbleText = text;
    });

    await _bubbleController.forward(from: 0);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scaleController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        <Listenable>[_shakeController, _scaleController, _bubbleController],
      ),
      builder: (BuildContext context, Widget? child) {
        return Container(
          color: _backgroundColor,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: const Text(
                    '🚪',
                    style: TextStyle(fontSize: 120),
                  ),
                ),
              ),
              Positioned(
                top: math.max(24, MediaQuery.of(context).size.height * 0.15),
                left: 24,
                right: 24,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _bubbleOpacity.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _bubbleText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isFlashing)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(color: Colors.black.withValues(alpha: 0.55)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

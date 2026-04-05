import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';

class KnockDetectorService {
  static const double _mobileKnockThreshold = 18.0;
  static const double _desktopKnockThresholdDb = -25.0;
  static const Duration _cooldownDuration = Duration(milliseconds: 600);
  static const Duration _doubleKnockWindow = Duration(milliseconds: 400);
  static const Duration _desktopSampleInterval = Duration(milliseconds: 100);

  void Function()? onKnock;
  void Function()? onDoubleKnock;

  final AudioRecorder _audioRecorder = AudioRecorder();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  DateTime? _lastKnockAt;
  DateTime? _lastKnockTriggeredAt;
  bool _isRunning = false;

  Future<void> start() async {
    if (_isRunning) {
      return;
    }

    _isRunning = true;

    if (Platform.isAndroid || Platform.isIOS) {
      _startMobileDetection();
      return;
    }

    if (Platform.isWindows || Platform.isMacOS) {
      await _startDesktopDetection();
      return;
    }

    _isRunning = false;
  }

  void stop() {
    if (!_isRunning) {
      return;
    }

    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    unawaited(_stopDesktopRecorder());

    _isRunning = false;
  }

  void dispose() {
    stop();
    _audioRecorder.dispose();
  }

  void _startMobileDetection() {
    _accelerometerSubscription?.cancel();

    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      final double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > _mobileKnockThreshold) {
        _handleKnock();
      }
    });
  }

  Future<void> _startDesktopDetection() async {
    _amplitudeSubscription?.cancel();

    final bool hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _isRunning = false;
      return;
    }

    final bool isRecording = await _audioRecorder.isRecording();
    if (isRecording) {
      await _audioRecorder.stop();
    }

    final String path =
        '${Directory.systemTemp.path}/knockknock_${DateTime.now().microsecondsSinceEpoch}.wav';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );

    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(_desktopSampleInterval)
        .listen((Amplitude amplitude) {
      if (amplitude.current > _desktopKnockThresholdDb) {
        _handleKnock();
      }
    });
  }

  void _handleKnock() {
    final DateTime now = DateTime.now();

    final DateTime? lastKnockTriggeredAt = _lastKnockTriggeredAt;
    if (lastKnockTriggeredAt != null &&
        now.difference(lastKnockTriggeredAt) < _cooldownDuration) {
      return;
    }

    final DateTime? previousKnockAt = _lastKnockAt;
    _lastKnockAt = now;

    _lastKnockTriggeredAt = now;
    onKnock?.call();

    if (previousKnockAt != null &&
        now.difference(previousKnockAt) <= _doubleKnockWindow) {
      onDoubleKnock?.call();
    }
  }

  Future<void> _stopDesktopRecorder() async {
    final bool isRecording = await _audioRecorder.isRecording();
    if (isRecording) {
      await _audioRecorder.stop();
    }
  }
}

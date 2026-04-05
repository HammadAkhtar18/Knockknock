import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef AccelerometerStreamFactory = Stream<AccelerometerEvent> Function();
typedef NowProvider = DateTime Function();

abstract class RecorderClient {
  Future<bool> hasPermission();
  Future<bool> isRecording();
  Future<void> stop();
  Future<void> start(RecordConfig config, {required String path});
  Stream<Amplitude> onAmplitudeChanged(Duration interval);
  Future<void> dispose();
}

class RecordPackageRecorderClient implements RecorderClient {
  RecordPackageRecorderClient({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<bool> isRecording() => _recorder.isRecording();

  @override
  Future<void> stop() => _recorder.stop();

  @override
  Future<void> start(RecordConfig config, {required String path}) =>
      _recorder.start(config, path: path);

  @override
  Stream<Amplitude> onAmplitudeChanged(Duration interval) =>
      _recorder.onAmplitudeChanged(interval);

  @override
  Future<void> dispose() => _recorder.dispose();
}

class KnockDetectorService {
  KnockDetectorService({
    RecorderClient? recorderClient,
    AccelerometerStreamFactory? accelerometerStreamFactory,
    NowProvider? nowProvider,
    bool Function()? isMobilePlatform,
    bool Function()? isDesktopPlatform,
  })  : _audioRecorder = recorderClient ?? RecordPackageRecorderClient(),
        _accelerometerStreamFactory =
            accelerometerStreamFactory ?? accelerometerEventStream,
        _nowProvider = nowProvider ?? DateTime.now,
        _isMobilePlatform =
            isMobilePlatform ?? (() => Platform.isAndroid || Platform.isIOS),
        _isDesktopPlatform =
            isDesktopPlatform ?? (() => Platform.isWindows || Platform.isMacOS);

  static const double mobileKnockThreshold = 18.0;
  static const double desktopKnockThresholdDb = -25.0;
  static const Duration cooldownDuration = Duration(milliseconds: 600);
  static const Duration doubleKnockWindow = Duration(milliseconds: 400);
  static const Duration desktopSampleInterval = Duration(milliseconds: 100);

  void Function()? onKnock;
  void Function()? onDoubleKnock;

  final RecorderClient _audioRecorder;
  final AccelerometerStreamFactory _accelerometerStreamFactory;
  final NowProvider _nowProvider;
  final bool Function() _isMobilePlatform;
  final bool Function() _isDesktopPlatform;

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

    if (_isMobilePlatform()) {
      _startMobileDetection();
      return;
    }

    if (_isDesktopPlatform()) {
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
    unawaited(_audioRecorder.dispose());
  }

  @visibleForTesting
  void processMobileMagnitude(double magnitude) {
    if (magnitude > mobileKnockThreshold) {
      _handleKnock();
    }
  }

  @visibleForTesting
  void processDesktopAmplitude(double currentDb) {
    if (currentDb > desktopKnockThresholdDb) {
      _handleKnock();
    }
  }

  void _startMobileDetection() {
    _accelerometerSubscription?.cancel();

    _accelerometerSubscription = _accelerometerStreamFactory().listen((event) {
      final double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      processMobileMagnitude(magnitude);
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
        '${Directory.systemTemp.path}/knockknock_${_nowProvider().microsecondsSinceEpoch}.wav';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );

    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(desktopSampleInterval)
        .listen((amplitude) {
      processDesktopAmplitude(amplitude.current);
    });
  }

  void _handleKnock() {
    final DateTime now = _nowProvider();
    final DateTime? previousKnockAt = _lastKnockAt;
    _lastKnockAt = now;

    if (previousKnockAt != null &&
        now.difference(previousKnockAt) <= doubleKnockWindow) {
      _lastKnockTriggeredAt = now;
      onDoubleKnock?.call();
      return;
    }

    final DateTime? lastKnockTriggeredAt = _lastKnockTriggeredAt;
    if (lastKnockTriggeredAt != null &&
        now.difference(lastKnockTriggeredAt) < cooldownDuration) {
      return;
    }

    _lastKnockTriggeredAt = now;
    onKnock?.call();
  }

  Future<void> _stopDesktopRecorder() async {
    final bool isRecording = await _audioRecorder.isRecording();
    if (isRecording) {
      await _audioRecorder.stop();
    }
  }
}

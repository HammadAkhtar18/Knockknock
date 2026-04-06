import 'dart:math';

import 'package:just_audio/just_audio.dart';

abstract class AudioPlayerClient {
  Future<void> setLoopMode(LoopMode mode);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> setAsset(String assetPath);
  Future<void> play();
  Future<void> dispose();
}

class JustAudioPlayerClient implements AudioPlayerClient {
  JustAudioPlayerClient({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer();

  final AudioPlayer _audioPlayer;

  @override
  Future<void> setLoopMode(LoopMode mode) => _audioPlayer.setLoopMode(mode);

  @override
  Future<void> setVolume(double volume) => _audioPlayer.setVolume(volume);

  @override
  Future<void> stop() => _audioPlayer.stop();

  @override
  Future<void> setAsset(String assetPath) => _audioPlayer.setAsset(assetPath);

  @override
  Future<void> play() => _audioPlayer.play();

  @override
  Future<void> dispose() => _audioPlayer.dispose();
}

class ResponseAudioService {
  ResponseAudioService({
    Random? random,
    AudioPlayerClient? audioPlayerClient,
  })  : _random = random ?? Random(),
        _audioPlayer = audioPlayerClient ?? JustAudioPlayerClient();

  final AudioPlayerClient _audioPlayer;
  final Random _random;

  final List<_KnockResponse> _singleKnockResponses = const [
    _KnockResponse(
      assetPath: 'assets/audio/come_in.txt',
      text: 'Come in 😳',
    ),
    _KnockResponse(
      assetPath: 'assets/audio/whos_there.txt',
      text: "Who's there??",
    ),
    _KnockResponse(
      assetPath: 'assets/audio/not_now.txt',
      text: 'Not now bro 🙄',
    ),
  ];

  final _KnockResponse _doubleKnockResponse = const _KnockResponse(
    assetPath: 'assets/audio/seriously.txt',
    text: 'SERIOUSLY?! 😤',
  );

  int? _lastSingleKnockIndex;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _audioPlayer.setLoopMode(LoopMode.off);
      _isInitialized = true;
    } on Exception {
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> setVolume(double volume) async {
    final double safeVolume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(safeVolume);
  }

  Future<String> playKnockResponse() async {
    final response = _pickSingleKnockResponse();
    await _playResponse(response);
    return response.text;
  }

  Future<String> playDoubleKnockResponse() async {
    await _playResponse(_doubleKnockResponse);
    return _doubleKnockResponse.text;
  }

  void dispose() {
    _audioPlayer.dispose();
  }

  _KnockResponse _pickSingleKnockResponse() {
    if (_singleKnockResponses.length == 1) {
      _lastSingleKnockIndex = 0;
      return _singleKnockResponses.first;
    }

    int nextIndex;
    do {
      nextIndex = _random.nextInt(_singleKnockResponses.length);
    } while (nextIndex == _lastSingleKnockIndex);

    _lastSingleKnockIndex = nextIndex;
    return _singleKnockResponses[nextIndex];
  }

  Future<void> _playResponse(_KnockResponse response) async {
    if (!_isInitialized) {
      throw StateError(
        'ResponseAudioService.init() must be called before playing audio.',
      );
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset(response.assetPath);
      await _audioPlayer.play();
    } on Exception {
      // Ignore playback errors for now because placeholder assets are .txt files.
      // The caller still receives the selected response text.
    }
  }
}

class _KnockResponse {
  const _KnockResponse({
    required this.assetPath,
    required this.text,
  });

  final String assetPath;
  final String text;
}

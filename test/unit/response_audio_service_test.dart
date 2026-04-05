import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:knockknock_ai/services/response_audio_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'response_audio_service_test.mocks.dart';

class _CyclingRandom implements Random {
  _CyclingRandom(this._values);

  final List<int> _values;
  int _index = 0;

  @override
  int nextInt(int max) {
    final int value = _values[_index % _values.length] % max;
    _index++;
    return value;
  }

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() => nextInt(10000) / 10000;

}

@GenerateMocks([AudioPlayerClient])
void main() {
  group('ResponseAudioService', () {
    late MockAudioPlayerClient audioPlayer;
    late ResponseAudioService service;

    setUp(() {
      audioPlayer = MockAudioPlayerClient();
      when(audioPlayer.setLoopMode(any)).thenAnswer((_) => Future<void>.value());
      when(audioPlayer.stop()).thenAnswer((_) => Future<void>.value());
      when(audioPlayer.setAsset(any)).thenAnswer((_) => Future<void>.value());
      when(audioPlayer.play()).thenAnswer((_) => Future<void>.value());
      when(audioPlayer.dispose()).thenAnswer((_) => Future<void>.value());

      service = ResponseAudioService(
        audioPlayerClient: audioPlayer,
        random: _CyclingRandom(<int>[0, 0, 1, 1, 2, 2]),
      );
    });

    test('playKnockResponse() never returns same text twice in a row', () async {
      await service.init();

      final List<String> responses = <String>[];
      for (int i = 0; i < 8; i++) {
        responses.add(await service.playKnockResponse());
      }

      for (int i = 1; i < responses.length; i++) {
        expect(responses[i], isNot(equals(responses[i - 1])));
      }
    });

    test('playDoubleKnockResponse() always returns "SERIOUSLY?! 😤"', () async {
      await service.init();

      final String response = await service.playDoubleKnockResponse();

      expect(response, 'SERIOUSLY?! 😤');
    });

    test('Calling play before init() throws clear error', () async {
      expect(
        () => service.playKnockResponse(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            'ResponseAudioService.init() must be called before playing audio.',
          ),
        ),
      );

      verifyNever(audioPlayer.stop());
      verifyNever(audioPlayer.setLoopMode(LoopMode.off));
    });
  });
}

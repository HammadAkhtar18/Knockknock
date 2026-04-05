import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knockknock_ai/services/knock_detector_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'knock_detector_test.mocks.dart';

@GenerateMocks([RecorderClient])
void main() {
  group('KnockDetectorService', () {
    late MockRecorderClient recorderClient;
    late DateTime fakeNow;
    late KnockDetectorService service;
    int knockCount = 0;
    int doubleKnockCount = 0;

    setUp(() {
      recorderClient = MockRecorderClient();
      fakeNow = DateTime(2026, 1, 1, 12, 0, 0);
      service = KnockDetectorService(
        recorderClient: recorderClient,
        nowProvider: () => fakeNow,
      )
        ..onKnock = () {
          knockCount++;
        }
        ..onDoubleKnock = () {
          doubleKnockCount++;
        };

      knockCount = 0;
      doubleKnockCount = 0;
      when(recorderClient.isRecording()).thenAnswer((_) async => false);
      when(recorderClient.dispose()).thenAnswer((_) => Future<void>.value());
    });

    test('onKnock fires when magnitude > 18.0', () {
      service.processMobileMagnitude(18.1);

      expect(knockCount, 1);
      expect(doubleKnockCount, 0);
    });

    test('onKnock does NOT fire when magnitude < 18.0', () {
      service.processMobileMagnitude(17.9);

      expect(knockCount, 0);
      expect(doubleKnockCount, 0);
    });

    test('Cooldown blocks second knock within 600ms', () {
      fakeAsync((async) {
        service.processMobileMagnitude(20.0);
        expect(knockCount, 1);

        async.elapse(const Duration(milliseconds: 500));
        fakeNow = fakeNow.add(const Duration(milliseconds: 500));
        service.processMobileMagnitude(20.0);

        expect(knockCount, 1);
        expect(doubleKnockCount, 0);
      });
    });

    test('onDoubleKnock fires for two knocks within 400ms', () {
      fakeAsync((async) {
        service.processMobileMagnitude(20.0);
        expect(knockCount, 1);

        async.elapse(const Duration(milliseconds: 300));
        fakeNow = fakeNow.add(const Duration(milliseconds: 300));
        service.processMobileMagnitude(20.0);

        expect(knockCount, 1);
        expect(doubleKnockCount, 1);
      });
    });

    test('dispose() cleans up without error', () {
      expect(service.dispose, returnsNormally);
      verify(recorderClient.dispose()).called(1);
    });
  });
}

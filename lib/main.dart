import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/knockknock_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool isMicrophoneDenied = false;

  if (Platform.isWindows || Platform.isMacOS) {
    final PermissionStatus microphoneStatus = await Permission.microphone.request();
    isMicrophoneDenied = microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied;
  }

  runApp(KnockKnockApp(navigatorKey: navigatorKey));

  if (isMicrophoneDenied) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? context = navigatorKey.currentContext;
      if (context == null) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Microphone Permission Needed'),
            content: const Text(
              'KnockKnock AI needs microphone access on desktop to detect knocks and play responses.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }
}

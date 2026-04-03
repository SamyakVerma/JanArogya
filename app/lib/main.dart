import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase — safe init, app works without it
  try {
    // ignore: depend_on_referenced_packages
    await _initFirebase();
  } catch (_) {}

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const JanArogyaApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  try {
    // Only initialize if firebase_options.dart is configured
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {}
}

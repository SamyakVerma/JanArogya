import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class JanArogyaApp extends StatelessWidget {
  const JanArogyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'JanArogya',
      debugShowCheckedModeBanner: false,
      themeMode: provider.themeMode,
      theme:     AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}

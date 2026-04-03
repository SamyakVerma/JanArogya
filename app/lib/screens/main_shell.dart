import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'scan_entry_screen.dart';
import 'history_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  final _screens = const [
    HomeScreen(),
    ScanEntryScreen(),
    HistoryScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppProvider>().langCode;
    final s    = AppStrings(lang);

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home), label: s.navHome),
          BottomNavigationBarItem(icon: const Icon(Icons.camera_alt_outlined),
              activeIcon: const Icon(Icons.camera_alt), label: s.navScan),
          BottomNavigationBarItem(icon: const Icon(Icons.history_outlined),
              activeIcon: const Icon(Icons.history), label: s.navHistory),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble), label: s.navChat),
          BottomNavigationBarItem(icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings), label: s.navSettings),
        ],
      ),
    );
  }
}

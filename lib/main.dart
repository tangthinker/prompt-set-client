import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Size, Brightness;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prompt_set_client/widgets/macos_window_buttons.dart';
import 'package:window_manager/window_manager.dart';
import 'package:prompt_set_client/views/home_page.dart';
import 'package:prompt_set_client/views/settings_page.dart';
import 'package:prompt_set_client/providers/prompt_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        windowManager.setBrightness(brightness);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) {
      setState(() {});
      if (Platform.isWindows) {
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        windowManager.setBrightness(brightness);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return CupertinoApp(
      title: 'Prompt Set',
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: CupertinoColors.activeBlue,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final pageIndex = ref.watch(navigationIndexProvider);
      final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

      return CupertinoPageScaffold(
        child: Stack(
          children: [
            IndexedStack(
              index: pageIndex,
              children: const [
                HomePage(),
                SettingsPage(),
              ],
            ),
            if (Platform.isMacOS || Platform.isWindows)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 40,
                  child: DragToMoveArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 80, top: 8),
                      child: Text(
                        ' ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? CupertinoColors.inactiveGray : CupertinoColors.inactiveGray,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (Platform.isWindows)
              const Positioned(top: 0, right: 0, child: MacosWindowButtons()),
          ],
        ),
      );
    });
  }
}

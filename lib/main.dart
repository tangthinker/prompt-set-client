import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode, Size, Brightness;
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:prompt_set_client/widgets/macos_window_buttons.dart';
import 'package:window_manager/window_manager.dart';

Future<void> _configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS) {
    await _configureMacosWindowUtils();
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    if (Platform.isWindows) {
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1024, 768),
        center: true,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  runApp(const MyApp());
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
    // 初始化同步亮度给原生窗口
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
    if (Platform.isWindows) {
      final brightness = MediaQuery.platformBrightnessOf(context);
      return CupertinoApp(
        title: 'Prompt Set Client',
        theme: CupertinoThemeData(brightness: brightness),
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      );
    }

    return MacosApp(
      title: 'Prompt Set Client',
      theme: MacosThemeData.light(),
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _pageIndex = 0;

  Widget _buildWindowsContent() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return CupertinoPageScaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 200,
                color: isDark
                    ? const Color(0xFF1A1A1A)
                    : CupertinoColors.systemGroupedBackground,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    CupertinoListSection.insetGrouped(
                      backgroundColor: CupertinoColors.transparent,
                      children: [
                        CupertinoListTile(
                          leading: Icon(
                            CupertinoIcons.home,
                            color: isDark ? CupertinoColors.white : null,
                          ),
                          title: Text(
                            'Home',
                            style: TextStyle(
                              color: isDark ? CupertinoColors.white : null,
                            ),
                          ),
                          onTap: () => setState(() => _pageIndex = 0),
                          backgroundColor: _pageIndex == 0
                              ? (isDark
                                    ? CupertinoColors.systemFill.withOpacity(
                                        0.4,
                                      )
                                    : CupertinoColors.systemFill)
                              : null,
                        ),
                        CupertinoListTile(
                          leading: Icon(
                            CupertinoIcons.settings,
                            color: isDark ? CupertinoColors.white : null,
                          ),
                          title: Text(
                            'Settings',
                            style: TextStyle(
                              color: isDark ? CupertinoColors.white : null,
                            ),
                          ),
                          onTap: () => setState(() => _pageIndex = 1),
                          backgroundColor: _pageIndex == 1
                              ? (isDark
                                    ? CupertinoColors.systemFill.withOpacity(
                                        0.4,
                                      )
                                    : CupertinoColors.systemFill)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _pageIndex,
                  children: const [HomePage(), SettingsPage()],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 32,
              child: DragToMoveArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [MacosWindowButtons()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _buildWindowsContent();
    }
    return Stack(
      children: [
        MacosWindow(
          sidebar: Sidebar(
            minWidth: 200,
            builder: (context, scrollController) {
              return SidebarItems(
                currentIndex: _pageIndex,
                onChanged: (index) {
                  setState(() => _pageIndex = index);
                },
                items: const [
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.home),
                    label: Text('Home'),
                  ),
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.settings),
                    label: Text('Settings'),
                  ),
                ],
              );
            },
          ),
          child: IndexedStack(
            index: _pageIndex,
            children: const [HomePage(), SettingsPage()],
          ),
        ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
      return CupertinoPageScaffold(
        backgroundColor: isDark
            ? const Color(0xFF000000)
            : const Color(0xFFFFFFFF),
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            'Home',
            style: TextStyle(color: isDark ? CupertinoColors.white : null),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : null,
        ),
        child: Center(
          child: Text(
            'Welcome to Prompt Set Client',
            style: TextStyle(color: isDark ? CupertinoColors.white : null),
          ),
        ),
      );
    }

    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Home'),
        actions: [
          ToolBarIconButton(
            label: 'Add',
            icon: const MacosIcon(CupertinoIcons.add),
            onPressed: () {},
            showLabel: false,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const Center(child: Text('Welcome to Prompt Set Client'));
          },
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
      return CupertinoPageScaffold(
        backgroundColor: isDark
            ? const Color(0xFF000000)
            : const Color(0xFFFFFFFF),
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            'Settings',
            style: TextStyle(color: isDark ? CupertinoColors.white : null),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : null,
        ),
        child: Center(
          child: Text(
            'Settings Page',
            style: TextStyle(color: isDark ? CupertinoColors.white : null),
          ),
        ),
      );
    }

    return MacosScaffold(
      toolBar: const ToolBar(title: Text('Settings')),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return const Center(child: Text('Settings Page'));
          },
        ),
      ],
    );
  }
}

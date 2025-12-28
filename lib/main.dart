import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode, Size;
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return CupertinoApp(
        title: 'Prompt Set Client',
        theme: const CupertinoThemeData(),
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
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 200,
                color: CupertinoColors.systemGroupedBackground,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    CupertinoListSection.insetGrouped(
                      backgroundColor: CupertinoColors.transparent,
                      children: [
                        CupertinoListTile(
                          leading: const Icon(CupertinoIcons.home),
                          title: const Text('Home'),
                          onTap: () => setState(() => _pageIndex = 0),
                          backgroundColor: _pageIndex == 0
                              ? CupertinoColors.systemFill
                              : null,
                        ),
                        CupertinoListTile(
                          leading: const Icon(CupertinoIcons.settings),
                          title: const Text('Settings'),
                          onTap: () => setState(() => _pageIndex = 1),
                          backgroundColor: _pageIndex == 1
                              ? CupertinoColors.systemFill
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
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Home')),
        child: Center(child: Text('Welcome to Prompt Set Client')),
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
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Settings')),
        child: Center(child: Text('Settings Page')),
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

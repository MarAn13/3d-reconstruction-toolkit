import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:reconstruction_3d/pages/database.dart';
import 'package:reconstruction_3d/pages/history_page.dart';
import 'package:reconstruction_3d/pages/home_page.dart';
import 'package:reconstruction_3d/pages/settings_page.dart';

void main() {
  runApp(MainApp(initPageIndex: 1));
}

class MainApp extends StatefulWidget {
  final int initPageIndex;
  MainApp({super.key, required this.initPageIndex});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  AppBar? globalAppBar;
  void updateGlobalAppBar(AppBar appBar) {
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      setState(() {
        globalAppBar = appBar;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedPageIndex = widget.initPageIndex;
    _navigateBottomBar(_selectedPageIndex);
  }

  int _selectedPageIndex = 1;
  Widget? _currentPage;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedPageIndex = index;
      switch (index) {
        case 0:
          _currentPage = HistoryPage(updateGlobalAppBar: updateGlobalAppBar);
          break;
        case 1:
          _currentPage = HomePage(updateGlobalAppBar: updateGlobalAppBar);
          break;
        case 2:
          _currentPage = SettingsPage(updateGlobalAppBar: updateGlobalAppBar);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffbb86fc),
            brightness: Brightness.dark,
          ),
          useMaterial3: true),
      home: Scaffold(
        appBar: globalAppBar,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedPageIndex,
          onTap: _navigateBottomBar,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: "history"),
            BottomNavigationBarItem(icon: Icon(Icons.radio_button_checked), label: "reconstruction"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "settings")
          ],
        ),
        body: _currentPage,
      ),
    );
  }
}

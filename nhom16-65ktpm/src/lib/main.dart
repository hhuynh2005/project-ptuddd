import 'package:flutter/material.dart';
import 'core/database/database_factory_setup.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDatabaseFactory();
  runApp(const GoodDeedsFundApp());
}

class GoodDeedsFundApp extends StatefulWidget {
  const GoodDeedsFundApp({super.key});

  @override
  State<GoodDeedsFundApp> createState() => _GoodDeedsFundAppState();
}

class _GoodDeedsFundAppState extends State<GoodDeedsFundApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: MainNavigationScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppState appState;
  try {
    appState = AppState();
    await appState.init();
  } catch (e) {
    appState = AppState();
  }

  runApp(SQLMasterApp(state: appState));
}

class SQLMasterApp extends StatelessWidget {
  final AppState state;
  const SQLMasterApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLMaster Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
      ),
      home: HomeScreen(state: state),
    );
  }
}

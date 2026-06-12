import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear el estado SIN await — la app arranca inmediatamente
  final appState = AppState();

  // Lanzar init en background (no bloquea el arranque)
  appState.init();

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
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
      ),
      home: HomeScreen(state: state),
    );
  }
}

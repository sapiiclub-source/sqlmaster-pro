import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Captura errores de Flutter (widgets) y los muestra en pantalla
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Captura errores de Dart fuera del árbol de widgets
  AppState? appState;
  String? initError;

  try {
    appState = AppState();
    await appState.init();
  } catch (e) {
    initError = e.toString();
    appState = AppState(); // estado vacío como fallback
  }

  runApp(SQLMasterApp(state: appState!, initError: initError));
}

class SQLMasterApp extends StatelessWidget {
  final AppState state;
  final String? initError;
  const SQLMasterApp({super.key, required this.state, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQLMaster Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
      ),
      // Si hay error de init, muestra pantalla de debug en vez de crashear
      home: initError != null
          ? _ErrorScreen(error: initError!)
          : HomeScreen(state: state),
      // Captura errores de build de widgets
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return _ErrorScreen(error: details.exceptionAsString());
        };
        return child ?? const SizedBox();
      },
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚠️ Error de inicio',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Detalle del error:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      error,
                      style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 12,
                          fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

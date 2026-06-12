import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import 'mapa_screen.dart';
import 'sandbox_screen.dart';
import 'progreso_screen.dart';
import 'referencia_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<String> _frases = [
    '\"El conocimiento de SQL es poder sobre los datos.\"',
    '\"Una consulta bien escrita vale más que mil palabras.\"',
    '\"Los índices son el secreto de la velocidad.\"',
    '\"Normalizar es simplificar; desnormalizar es optimizar.\"',
    '\"Todo gran DBA empezó con un SELECT * FROM tabla.\"',
    '\"Los JOINs son puentes entre mundos de datos.\"',
    '\"La práctica constante construye el maestro SQL.\"',
    '\"Sin integridad referencial, los datos son caos.\"',
  ];

  String _getFrase() {
    final day = DateTime.now().weekday - 1;
    return _frases[day % _frases.length];
  }

  void _goToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.updateStreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Row(
              children: [
                Icon(Icons.storage_rounded, color: AppColors.cyan, size: 26),
                const SizedBox(width: 8),
                Text(
                  'SQLMaster Pro',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              _XpBadge(xp: widget.state.totalXp),
              const SizedBox(width: 8),
              _StreakBadge(streak: widget.state.streak),
              const SizedBox(width: 12),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _InicioTab(
                state: widget.state,
                frase: _getFrase(),
                onNavigate: _goToTab,
              ),
              MapaScreen(state: widget.state),
              SandboxScreen(state: widget.state),
              ProgresoScreen(state: widget.state),
              ReferenciaScreen(state: widget.state),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.cyan,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded),
                label: 'Mapa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.terminal_rounded),
                label: 'Sandbox',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Progreso',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded),
                label: 'Referencia',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar badges
// ---------------------------------------------------------------------------

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$xp XP',
            style: GoogleFonts.nunito(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: GoogleFonts.nunito(
              color: AppColors.orange,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// InicioTab (inline widget)
// ---------------------------------------------------------------------------

class _InicioTab extends StatelessWidget {
  final AppState state;
  final String frase;
  final void Function(int) onNavigate;

  const _InicioTab({
    required this.state,
    required this.frase,
    required this.onNavigate,
  });

  static const List<Map<String, dynamic>> _quickItems = [
    {
      'label': 'Mapa',
      'icon': Icons.map_rounded,
      'color': Color(0xFF00BCD4),
      'index': 1,
    },
    {
      'label': 'Sandbox',
      'icon': Icons.terminal_rounded,
      'color': Color(0xFF7C4DFF),
      'index': 2,
    },
    {
      'label': 'Progreso',
      'icon': Icons.bar_chart_rounded,
      'color': Color(0xFF4CAF50),
      'index': 3,
    },
    {
      'label': 'Referencia',
      'icon': Icons.menu_book_rounded,
      'color': Color(0xFFFF9800),
      'index': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final nextLesson = state.nextIncompleteLesson;
    final precision = state.totalAnswered > 0
        ? (state.correctAnswers / state.totalAnswered * 100).toStringAsFixed(0)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero greeting card
          _buildHeroCard(),
          const SizedBox(height: 16),

          // Motivational quote
          _buildQuoteCard(),
          const SizedBox(height: 16),

          // Continuar card
          if (nextLesson != null) ...[
            _buildContinuarCard(nextLesson.title),
            const SizedBox(height: 16),
          ],

          // Stats row
          _buildStatsRow(precision),
          const SizedBox(height: 20),

          // Quick access title
          Text(
            'Acceso rápido',
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Quick access grid
          _buildQuickGrid(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final xpForNext = state.xpForNextLevel;
    final xpCurrent = state.xpInCurrentLevel;
    final progress = xpForNext > 0 ? (xpCurrent / xpForNext).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withOpacity(0.3),
            AppColors.primary.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, DBA en formación! 🚀',
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.levelName,
            style: GoogleFonts.nunito(
              color: AppColors.cyan,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$xpCurrent / $xpForNext XP',
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Text('💡', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              frase,
              style: GoogleFonts.nunito(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuarCard(String lessonTitle) {
    return GestureDetector(
      onTap: () => onNavigate(1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.orange.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.play_circle_rounded,
                  color: AppColors.orange, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Continuar aprendiendo',
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lessonTitle,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.orange, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(String precision) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                '📚', '${state.completedLessons}', 'Lecciones')),
        const SizedBox(width: 10),
        Expanded(
            child:
                _buildStatCard('🔥', '${state.streak}', 'Racha')),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard('🎯', '$precision%', 'Precisión')),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: _quickItems.map((item) {
        final color = item['color'] as Color;
        return GestureDetector(
          onTap: () => onNavigate(item['index'] as int),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData,
                      color: color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
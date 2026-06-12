import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../state/app_state.dart';

// ─── XP Ring Painter ────────────────────────────────────────────────────────

class _XpRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  const _XpRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 10.0;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_XpRingPainter old) => old.progress != progress;
}

// ─── ProgresoScreen ──────────────────────────────────────────────────────────

class ProgresoScreen extends StatelessWidget {
  final AppState state;
  const ProgresoScreen({super.key, required this.state});

  // ── Section: XP Hero Card ──────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Builder(builder: (context) {
      final xpCurrent = state.xpInCurrentLevel;
      final xpNeeded = state.xpNeededForNextLevel;
      final progress = xpNeeded > 0 ? (xpCurrent / xpNeeded).clamp(0.0, 1.0) : 0.0;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.25)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, Colors.cyanAccent.withOpacity(0.05)],
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(90, 90),
                    painter: _XpRingPainter(progress),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.level}',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'nivel',
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.levelName,
                    style: GoogleFonts.nunito(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.totalXp} XP totales',
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xpCurrent / $xpNeeded XP para siguiente nivel',
                    style: GoogleFonts.nunito(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Section: Stats 2x2 Grid ────────────────────────────────────────────────

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final completedCount = state.completedLessons;
    final streak = state.streakDays;
    final bestStreak = state.bestStreak;
    final accuracy = state.avgScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _buildStatCard('📚', 'Lecciones', '$completedCount', Colors.cyanAccent),
          _buildStatCard('🔥', 'Racha', '$streak días', Colors.orangeAccent),
          _buildStatCard('🏆', 'Mejor racha', '$bestStreak días', Colors.amberAccent),
          _buildStatCard('🎯', 'Precisión', '${accuracy.toStringAsFixed(0)}%', Colors.greenAccent),
        ],
      ),
    );
  }

  // ── Section: World Progress ────────────────────────────────────────────────

  Widget _buildMundos() {
    final mundos = state.mundos;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso por Mundo',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(mundos.length, (i) {
            final m = mundos[i];
            final color = AppColors.worldColors[i % AppColors.worldColors.length];
            final done = m.completedLessons;
            final total = m.totalLessons;
            final progress = total > 0 ? done / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.nombre,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$done/$total',
                              style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: color.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Section: Achievements ─────────────────────────────────────────────────

  static const List<Map<String, String>> _allAchievements = [
    {'id': 'first_lesson', 'emoji': '🎉', 'name': 'Primera lección', 'desc': 'Completa tu primera lección'},
    {'id': 'streak_3', 'emoji': '🔥', 'name': 'Racha de 3 días', 'desc': '3 días consecutivos'},
    {'id': 'streak_7', 'emoji': '🌟', 'name': 'Racha de 7 días', 'desc': '7 días consecutivos'},
    {'id': 'world_1', 'emoji': '🏅', 'name': 'Fundamentos SQL', 'desc': 'Completa el mundo 1'},
    {'id': 'world_2', 'emoji': '🥈', 'name': 'SQL Intermedio', 'desc': 'Completa el mundo 2'},
    {'id': 'world_3', 'emoji': '🥇', 'name': 'SQL Avanzado', 'desc': 'Completa el mundo 3'},
    {'id': 'perfect_10', 'emoji': '💯', 'name': 'Perfecto', 'desc': '10/10 en una lección'},
    {'id': 'speed_run', 'emoji': '⚡', 'name': 'Rayo', 'desc': 'Lección en menos de 2 min'},
    {'id': 'sandbox_5', 'emoji': '🧪', 'name': 'Experimentador', 'desc': '5 queries en Sandbox'},
    {'id': 'level_5', 'emoji': '🚀', 'name': 'Nivel 5', 'desc': 'Alcanza el nivel 5'},
  ];

  Widget _buildLogros() {
    final unlocked = state.unlockedAchievements;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logros',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: _allAchievements.map((a) {
              final isUnlocked = unlocked.contains(a['id']);
              return Opacity(
                opacity: isUnlocked ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked
                          ? AppColors.accent.withOpacity(0.4)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isUnlocked ? a['emoji']! : '🔒',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              a['name']!,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              a['desc']!,
                              style: GoogleFonts.nunito(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Section: Weekly Bar Chart ─────────────────────────────────────────────

  Widget _buildWeeklyActivity() {
    final activity = state.weeklyActivity; // List<int>, 7 items
    final maxVal = activity.isEmpty ? 1 : activity.reduce(math.max);
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final today = DateTime.now().weekday - 1; // 0=Mon

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad semanal',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final val = i < activity.length ? activity[i] : 0;
                final barH = maxVal > 0 ? (val / maxVal) * 60 : 0.0;
                final isToday = i == today;
                final barColor = isToday ? AppColors.accent : AppColors.primary.withOpacity(0.6);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (val > 0)
                      Text(
                        '$val',
                        style: GoogleFonts.nunito(
                          color: isToday ? AppColors.accent : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 24,
                      height: barH.toDouble().clamp(4, 60),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[i],
                      style: GoogleFonts.nunito(
                        color: isToday ? Colors.white : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            'Mi Progreso',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              _buildStatsGrid(),
              _buildMundos(),
              _buildLogros(),
              _buildWeeklyActivity(),
            ],
          ),
        ),
      ),
    );
  }
}

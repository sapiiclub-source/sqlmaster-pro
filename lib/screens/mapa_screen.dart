import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../models/models.dart' hide Lesson, QuizQuestion, UserProgress;
import 'leccion_screen.dart';

class MapaScreen extends StatelessWidget {
  final AppState state;
  const MapaScreen({super.key, required this.state});

  static const List<String> _worldTitles = [
    'Fundamentos SQL', 'SQL Intermedio', 'SQL Avanzado', 'SQL Server Pro', 'Oracle Master',
  ];
  static const List<int> _worldTotals = [8, 8, 8, 6, 6];

  int _completedInWorld(int world) =>
      state.worldLessons(world).where((l) => state.isLessonCompleted(l.id)).length;
  int _totalInWorld(int world) => _worldTotals[world - 1];
  bool _isWorldComplete(int world) => _completedInWorld(world) >= _totalInWorld(world);

  List<Lesson> _lessonsForWorld(int world) {
    final lessons = state.lessons.where((l) => l.worldNumber == world).toList();
    lessons.sort((a, b) => a.id.compareTo(b.id));
    return lessons;
  }

  String _getLessonStatus(Lesson lesson, int worldIndex) {
    final world = worldIndex + 1;
    if (state.isLessonCompleted(lesson.id)) return 'completed';
    if (world > 1) {
      for (int w = 1; w < world; w++) {
        if (!_isWorldComplete(w)) return 'locked';
      }
    }
    final worldLessons = _lessonsForWorld(world);
    final idx = worldLessons.indexWhere((l) => l.id == lesson.id);
    if (idx < 0) return 'locked';
    if (idx == 0) return 'available';
    return state.isLessonCompleted(worldLessons[idx - 1].id) ? 'available' : 'locked';
  }

  Widget _buildLessonTile(BuildContext context, Lesson lesson, String status, int wi) {
    final wc = AppColors.worldColors[wi];
    final isLocked = status == 'locked';
    final isAvailable = status == 'available';
    final isCompleted = status == 'completed';
    final leading = isCompleted
        ? CircleAvatar(radius: 22, backgroundColor: AppColors.success, child: const Icon(Icons.check_circle, color: Colors.white))
        : isAvailable
            ? CircleAvatar(radius: 22, backgroundColor: wc, child: const Icon(Icons.play_arrow, color: Colors.white))
            : CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade700, child: Icon(Icons.lock, color: Colors.grey.shade400, size: 20));
    return Opacity(
      opacity: isLocked ? 0.4 : 1.0,
      child: InkWell(
        onTap: isLocked
            ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa las lecciones anteriores primero')))
            : isAvailable
                ? () { state.startLesson(lesson.id); Navigator.push(context, MaterialPageRoute(builder: (_) => LeccionScreen(state: state, lessonId: lesson.id))); }
                : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            leading, const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lesson.title, style: GoogleFonts.nunito(color: Colors.white, fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
              Text(lesson.description, style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            if (isAvailable) Icon(Icons.arrow_forward_ios, color: AppColors.accent, size: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildWorldSection(BuildContext context, int wi) {
    final world = wi + 1;
    final wc = AppColors.worldColors[wi];
    final done = _completedInWorld(world);
    final total = _totalInWorld(world);
    final lessons = _lessonsForWorld(world);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(color: wc.withOpacity(0.15), border: Border(left: BorderSide(color: wc, width: 4))),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: wc, child: Text('$world', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_worldTitles[wi], style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$done/$total lecciones', style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: total > 0 ? done / total : 0, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(wc), minHeight: 6),
          ])),
        ]),
      ),
      ...lessons.map((l) => _buildLessonTile(context, l, _getLessonStatus(l, wi), wi)),
      const SizedBox(height: 16),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Mapa del Curso', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppColors.surface),
        body: ListView.builder(padding: const EdgeInsets.only(bottom: 32), itemCount: 5, itemBuilder: (ctx, i) => _buildWorldSection(ctx, i)),
      ),
    );
  }
}

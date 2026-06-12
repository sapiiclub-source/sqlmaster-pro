import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_helper;
import '../data/course_content.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class UserProgress {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int completedLessons;
  final List<String> unlockedAchievements;

  const UserProgress({
    this.totalXp = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.completedLessons = 0,
    this.unlockedAchievements = const [],
  });

  UserProgress copyWith({
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? completedLessons,
    List<String>? unlockedAchievements,
  }) {
    return UserProgress(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      completedLessons: completedLessons ?? this.completedLessons,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_xp': totalXp,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity_date': lastActivityDate?.toIso8601String(),
      'completed_lessons': completedLessons,
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map, List<String> achievements) {
    return UserProgress(
      totalXp: (map['total_xp'] as int?) ?? 0,
      currentStreak: (map['current_streak'] as int?) ?? 0,
      longestStreak: (map['longest_streak'] as int?) ?? 0,
      lastActivityDate: map['last_activity_date'] != null
          ? DateTime.tryParse(map['last_activity_date'] as String)
          : null,
      completedLessons: (map['completed_lessons'] as int?) ?? 0,
      unlockedAchievements: achievements,
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? codeSnippet;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.codeSnippet,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? []),
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
      codeSnippet: json['codeSnippet'] as String?,
    );
  }
}

class Lesson {
  final String id;
  final String worldId;
  final int worldNumber;
  final int lessonNumber;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;
  final List<QuizQuestion> questions;
  final String theoryContent;
  final int estimatedMinutes;

  const Lesson({
    required this.id,
    required this.worldId,
    required this.worldNumber,
    required this.lessonNumber,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.questions,
    required this.theoryContent,
    required this.estimatedMinutes,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final questionsList = (json['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
    return Lesson(
      id: json['id'] as String? ?? '',
      worldId: json['worldId'] as String? ?? '',
      worldNumber: json['worldNumber'] as int? ?? 1,
      lessonNumber: json['lessonNumber'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📘',
      xpReward: json['xpReward'] as int? ?? 10,
      questions: questionsList,
      theoryContent: json['theoryContent'] as String? ?? '',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
    );
  }
}

// ─── AppState ─────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  UserProgress _progress = const UserProgress();
  List<Lesson> _lessons = [];
  bool isLoading = false;
  String? currentLessonId;
  List<QuizQuestion> currentQuizQuestions = [];
  int currentQuizIndex = 0;
  List<bool> quizAnswers = [];
  int quizXpEarned = 0;
  Database? _db;

  // ─── Getters ───────────────────────────────────────────────────────────────

  UserProgress get progress => _progress;
  List<Lesson> get lessons => List.unmodifiable(_lessons);

  int get totalLessons => _lessons.length;

  Lesson? get currentLesson => currentLessonId != null
      ? lessonById(currentLessonId!)
      : null;

  List<String> get unlockedAchievements => _progress.unlockedAchievements;

  /// Returns a list of 7 integers (Mon–Sun) representing lessons completed per day
  /// in the current week. Placeholder implementation returns zeros.
  List<int> get weeklyActivity => List<int>.filled(7, 0);

  // ─── Convenience getters for UI screens ──────────────────────────────────

  int get totalXp => _progress.totalXp;

  int get streak => _progress.currentStreak;
  int get streakDays => _progress.currentStreak;
  int get bestStreak => _progress.longestStreak;

  /// Current numeric level derived from totalXp.
  int get level {
    final xp = _progress.totalXp;
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 600) return 3;
    if (xp < 1000) return 4;
    if (xp < 1500) return 5;
    if (xp < 2200) return 6;
    if (xp < 3000) return 7;
    if (xp < 4000) return 8;
    if (xp < 5500) return 9;
    return 10;
  }

  static const List<int> _levelThresholds = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5500, 999999];

  int get xpInCurrentLevel {
    final lv = level;
    return _progress.totalXp - _levelThresholds[lv - 1];
  }

  int get xpForNextLevel => _levelThresholds[level] - _levelThresholds[level - 1];
  int get xpNeededForNextLevel => xpForNextLevel;

  String get levelName {
    const names = [
      'Estudiante SQL', 'Aprendiz de Datos', 'Consultor Junior', 'Analista SQL',
      'Desarrollador de BD', 'Arquitecto de Datos', 'Experto en Consultas',
      'Maestro SQL', 'Elite DBA', 'Grand Master DBA',
    ];
    final idx = (level - 1).clamp(0, names.length - 1);
    return names[idx];
  }

  int get completedLessons => _completedIds.length;

  /// Average score placeholder (0–100). Returns 0 until score tracking is implemented.
  double get avgScore => 0.0;

  /// Total quiz questions answered (placeholder).
  int get totalAnswered => 0;

  /// Total correct quiz answers (placeholder).
  int get correctAnswers => 0;

  /// Next lesson not yet completed, or null if all done.
  Lesson? get nextIncompleteLesson {
    try {
      return _lessons.firstWhere((l) => !isLessonCompleted(l.id));
    } catch (_) {
      return null;
    }
  }

  /// Per-world progress summary used by ProgresoScreen.
  List<_MundoProgress> get mundos {
    const worldNames = [
      'Mundo 1: SELECT Básico',
      'Mundo 2: Filtros y Orden',
      'Mundo 3: Joins y Relaciones',
      'Mundo 4: Agregación y Grupos',
      'Mundo 5: Subconsultas y Avanzado',
    ];
    return List.generate(5, (i) {
      final wn = i + 1;
      final wl = worldLessons(wn);
      final done = wl.where((l) => isLessonCompleted(l.id)).length;
      return _MundoProgress(
        nombre: worldNames[i],
        completedLessons: done,
        totalLessons: wl.length,
      );
    });
  }

  Lesson? lessonById(String id) {
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Lesson> worldLessons(int worldNumber) {
    final result = _lessons
        .where((l) => l.worldNumber == worldNumber)
        .toList()
      ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));
    return result;
  }

  bool isLessonCompleted(String id) {
    return _completedIds.contains(id);
  }

  bool isLessonAvailable(String id) {
    final lesson = lessonById(id);
    if (lesson == null) return false;

    // Mundo 1 siempre disponible
    if (lesson.worldNumber == 1) {
      if (lesson.lessonNumber == 1) return true;
      // Dentro del mundo, desbloqueo secuencial
      final prev = _lessons.firstWhere(
        (l) => l.worldNumber == 1 && l.lessonNumber == lesson.lessonNumber - 1,
        orElse: () => lesson,
      );
      if (prev.id == lesson.id) return true;
      return isLessonCompleted(prev.id);
    }

    // Otros mundos: el mundo anterior debe estar 100% completado
    final prevWorldLessons = worldLessons(lesson.worldNumber - 1);
    final prevWorldComplete = prevWorldLessons.isNotEmpty &&
        prevWorldLessons.every((l) => isLessonCompleted(l.id));
    if (!prevWorldComplete) return false;

    // Desbloqueo secuencial dentro del mundo
    if (lesson.lessonNumber == 1) return true;
    final prevInWorld = _lessons.firstWhere(
      (l) =>
          l.worldNumber == lesson.worldNumber &&
          l.lessonNumber == lesson.lessonNumber - 1,
      orElse: () => lesson,
    );
    if (prevInWorld.id == lesson.id) return true;
    return isLessonCompleted(prevInWorld.id);
  }

  Set<String> _completedIds = {};

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      await _initDb();
      await _loadProgress();
      await _loadLessons();
    } catch (e) {
      // Continuar con datos vacíos si hay error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Database init ────────────────────────────────────────────────────────

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_helper.join(dbPath, 'sqlmaster.db');

    _db = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS user_progress (
            id INTEGER PRIMARY KEY,
            total_xp INTEGER NOT NULL DEFAULT 0,
            current_streak INTEGER NOT NULL DEFAULT 0,
            longest_streak INTEGER NOT NULL DEFAULT 0,
            last_activity_date TEXT,
            completed_lessons INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS completed_lessons (
            lesson_id TEXT PRIMARY KEY,
            score INTEGER NOT NULL DEFAULT 0,
            xp_earned INTEGER NOT NULL DEFAULT 0,
            completed_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS achievements (
            achievement_id TEXT PRIMARY KEY,
            unlocked_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS sandbox_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sql_query TEXT NOT NULL,
            executed_at TEXT NOT NULL
          )
        ''');

        // Fila inicial de progreso
        await db.insert('user_progress', {
          'id': 1,
          'total_xp': 0,
          'current_streak': 0,
          'longest_streak': 0,
          'last_activity_date': null,
          'completed_lessons': 0,
        });
      },
    );
  }

  // ─── Load progress ────────────────────────────────────────────────────────

  Future<void> _loadProgress() async {
    if (_db == null) return;

    final rows = await _db!.query('user_progress', where: 'id = ?', whereArgs: [1]);
    final achievementRows = await _db!.query('achievements');
    final completedRows = await _db!.query('completed_lessons');

    final achievements = achievementRows
        .map((r) => r['achievement_id'] as String)
        .toList();

    _completedIds = completedRows
        .map((r) => r['lesson_id'] as String)
        .toSet();

    if (rows.isNotEmpty) {
      _progress = UserProgress.fromMap(rows.first, achievements);
    }
  }

  // ─── Save progress ────────────────────────────────────────────────────────

  Future<void> _saveProgress() async {
    if (_db == null) return;
    await _db!.insert(
      'user_progress',
      {'id': 1, ..._progress.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Load lessons ─────────────────────────────────────────────────────────

  Future<void> _loadLessons() async {
    final List<Lesson> all = [];

    for (final item in courseData) {
      try {
        final id = item['id'] as String? ?? '';
        final world = (item['world'] as int?) ?? 1;
        // Extraer número de lección del id: n1_l3 → 3
        final lessonNum = int.tryParse(id.split('_l').last) ?? 1;

        // Construir theoryContent desde theoryPages
        final pages = item['theoryPages'] as List? ?? [];
        final theoryContent = pages.map((p) {
          final t = p['title'] ?? '';
          final c = p['content'] ?? '';
          final code = p['code'];
          final key = p['keyConcept'];
          final buffer = StringBuffer('## $t\n$c');
          if (code != null) buffer.write('\n```\n$code\n```');
          if (key != null) buffer.write('\n> $key');
          return buffer.toString();
        }).join('\n\n');

        // Construir questions desde quizQuestions
        final quizList = item['quizQuestions'] as List? ?? [];
        final questions = quizList.map((q) {
          final opts = List<String>.from(q['options'] as List? ?? []);
          final correct = q['correct'];
          final correctIndex = correct is int ? correct : int.tryParse(correct?.toString() ?? '0') ?? 0;
          return QuizQuestion(
            id: '${id}_q${quizList.indexOf(q)}',
            question: q['question'] as String? ?? '',
            options: opts,
            correctIndex: correctIndex,
            explanation: q['explanation'] as String? ?? '',
            codeSnippet: q['code'] as String?,
          );
        }).toList();

        all.add(Lesson(
          id: id,
          worldId: 'world$world',
          worldNumber: world,
          lessonNumber: lessonNum,
          title: item['title'] as String? ?? '',
          description: item['objective'] as String? ?? '',
          emoji: _iconToEmoji(item['icon'] as String? ?? ''),
          xpReward: (item['xpReward'] as int?) ?? 100,
          questions: questions,
          theoryContent: theoryContent,
          estimatedMinutes: 10,
        ));
      } catch (_) {
        // Ignorar lecciones con error de parseo
      }
    }

    all.sort((a, b) {
      final worldCmp = a.worldNumber.compareTo(b.worldNumber);
      if (worldCmp != 0) return worldCmp;
      return a.lessonNumber.compareTo(b.lessonNumber);
    });

    _lessons = all;
  }

  String _iconToEmoji(String icon) {
    const map = {
      'help_outline': '❓', 'table_rows': '📋', 'filter_alt': '🔍',
      'sort': '↕️', 'functions': '∑', 'group_work': '👥',
      'rule': '📏', 'emoji_events': '🏆', 'join_inner': '🔗',
      'join_left': '⬅️', 'join_full': '↔️', 'layers': '📚',
      'account_tree': '🌳', 'alt_route': '🔀', 'text_fields': '🔤',
      'calendar_today': '📅', 'view_list': '📊', 'swap_vert': '⇅',
      'table_chart': '📈', 'speed': '⚡', 'sync_alt': '🔄',
      'visibility': '👁️', 'code': '💻', 'tune': '⚙️',
      'data_object': '{}', 'device_hub': '🔀', 'bug_report': '🐛',
      'settings': '⚙️', 'flash_on': '⚡', 'new_releases': '🆕',
      'integration_instructions': '📝', 'manage_search': '🔎',
      'repeat': '🔁', 'event': '📆', 'compare_arrows': '⇔',
    };
    return map[icon] ?? '📘';
  }

  // ─── Complete lesson ──────────────────────────────────────────────────────

  Future<void> completeLesson(String id, int score, int xp) async {
    if (_db == null) return;

    final now = DateTime.now();

    await _db!.insert(
      'completed_lessons',
      {
        'lesson_id': id,
        'score': score,
        'xp_earned': xp,
        'completed_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _completedIds.add(id);

    _progress = _progress.copyWith(
      totalXp: _progress.totalXp + xp,
      completedLessons: _completedIds.length,
    );

    await _saveProgress();
    await updateStreak();
    notifyListeners();
  }

  // ─── Unlock achievement ───────────────────────────────────────────────────

  Future<void> unlockAchievement(String id) async {
    if (_db == null) return;
    if (_progress.unlockedAchievements.contains(id)) return;

    final now = DateTime.now();
    await _db!.insert(
      'achievements',
      {
        'achievement_id': id,
        'unlocked_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final updated = List<String>.from(_progress.unlockedAchievements)..add(id);
    _progress = _progress.copyWith(unlockedAchievements: updated);
    notifyListeners();
  }

  // ─── Sandbox history ──────────────────────────────────────────────────────

  Future<void> addSandboxQuery(String sql) async {
    if (_db == null) return;
    await _db!.insert('sandbox_history', {
      'sql_query': sql,
      'executed_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Streak ───────────────────────────────────────────────────────────────

  Future<void> updateStreak() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = _progress.lastActivityDate;

    int newStreak = _progress.currentStreak;

    if (last == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // Mismo día, no cambiar racha
      } else if (diff == 1) {
        newStreak = _progress.currentStreak + 1;
      } else {
        // Se rompió la racha
        newStreak = 1;
      }
    }

    _progress = _progress.copyWith(
      currentStreak: newStreak,
      longestStreak: newStreak > _progress.longestStreak
          ? newStreak
          : _progress.longestStreak,
      lastActivityDate: now,
    );

    await _saveProgress();
    notifyListeners();
  }

  // ─── Quiz flow ────────────────────────────────────────────────────────────

  void startLesson(String id) {
    final lesson = lessonById(id);
    if (lesson == null) return;

    currentLessonId = id;
    currentQuizQuestions = List<QuizQuestion>.from(lesson.questions);
    currentQuizIndex = 0;
    quizAnswers = [];
    quizXpEarned = 0;
    notifyListeners();
  }

  void answerQuiz(int answerIndex) {
    if (currentQuizIndex >= currentQuizQuestions.length) return;

    final question = currentQuizQuestions[currentQuizIndex];
    final isCorrect = answerIndex == question.correctIndex;
    quizAnswers = List<bool>.from(quizAnswers)..add(isCorrect);

    if (isCorrect) {
      final lesson = currentLessonId != null ? lessonById(currentLessonId!) : null;
      if (lesson != null) {
        quizXpEarned += (lesson.xpReward ~/ lesson.questions.length.clamp(1, 9999));
      }
    }

    notifyListeners();
  }

  void nextQuizQuestion() {
    if (currentQuizIndex < currentQuizQuestions.length - 1) {
      currentQuizIndex++;
      notifyListeners();
    }
  }

  void resetQuiz() {
    currentLessonId = null;
    currentQuizQuestions = [];
    currentQuizIndex = 0;
    quizAnswers = [];
    quizXpEarned = 0;
    notifyListeners();
  }
}

// ─── MundoProgress ────────────────────────────────────────────────────────────

class _MundoProgress {
  final String nombre;
  final int completedLessons;
  final int totalLessons;

  const _MundoProgress({
    required this.nombre,
    required this.completedLessons,
    required this.totalLessons,
  });
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ─── Getters ───────────────────────────────────────────────────────────────

  UserProgress get progress => _progress;
  List<Lesson> get lessons => List.unmodifiable(_lessons);

  int get totalLessons => _lessons.length;

  Lesson? get currentLesson => currentLessonId != null
      ? lessonById(currentLessonId!)
      : null;

  List<String> get unlockedAchievements => _progress.unlockedAchievements;

  List<int> get weeklyActivity => List<int>.filled(7, 0);

  // ─── Convenience getters for UI screens ──────────────────────────────────

  int get totalXp => _progress.totalXp;

  int get streak => _progress.currentStreak;
  int get streakDays => _progress.currentStreak;
  int get bestStreak => _progress.longestStreak;

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

  double get avgScore => 0.0;

  int get totalAnswered => 0;

  int get correctAnswers => 0;

  Lesson? get nextIncompleteLesson {
    try {
      return _lessons.firstWhere((l) => !isLessonCompleted(l.id));
    } catch (_) {
      return null;
    }
  }

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

    if (lesson.worldNumber == 1) {
      if (lesson.lessonNumber == 1) return true;
      final prev = _lessons.firstWhere(
        (l) => l.worldNumber == 1 && l.lessonNumber == lesson.lessonNumber - 1,
        orElse: () => lesson,
      );
      if (prev.id == lesson.id) return true;
      return isLessonCompleted(prev.id);
    }

    final prevWorldLessons = worldLessons(lesson.worldNumber - 1);
    final prevWorldComplete = prevWorldLessons.isNotEmpty &&
        prevWorldLessons.every((l) => isLessonCompleted(l.id));
    if (!prevWorldComplete) return false;

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
    try { await _loadProgress(); } catch (_) {}
    try { await _loadLessons(); } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  // ─── Load progress ────────────────────────────────────────────────────────

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final completedJson = prefs.getString('completed_ids');
    if (completedJson != null) {
      final List<dynamic> list = jsonDecode(completedJson) as List<dynamic>;
      _completedIds = list.map((e) => e as String).toSet();
    }

    final achievementsJson = prefs.getString('unlocked_achievements');
    List<String> achievements = [];
    if (achievementsJson != null) {
      final List<dynamic> list = jsonDecode(achievementsJson) as List<dynamic>;
      achievements = list.map((e) => e as String).toList();
    }

    final progressMap = <String, dynamic>{
      'total_xp': prefs.getInt('total_xp') ?? 0,
      'current_streak': prefs.getInt('current_streak') ?? 0,
      'longest_streak': prefs.getInt('longest_streak') ?? 0,
      'last_activity_date': prefs.getString('last_activity_date'),
      'completed_lessons': _completedIds.length,
    };

    _progress = UserProgress.fromMap(progressMap, achievements);
  }

  // ─── Save progress ────────────────────────────────────────────────────────

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_xp', _progress.totalXp);
    await prefs.setInt('current_streak', _progress.currentStreak);
    await prefs.setInt('longest_streak', _progress.longestStreak);
    if (_progress.lastActivityDate != null) {
      await prefs.setString('last_activity_date', _progress.lastActivityDate!.toIso8601String());
    }
    await prefs.setString('completed_ids', jsonEncode(_completedIds.toList()));
    await prefs.setString('unlocked_achievements', jsonEncode(_progress.unlockedAchievements));
  }

  // ─── Load lessons ─────────────────────────────────────────────────────────

  Future<void> _loadLessons() async {
    final List<Lesson> all = [];

    for (final item in courseData) {
      try {
        final id = item['id'] as String? ?? '';
        final world = (item['world'] as int?) ?? 1;
        final lessonNum = int.tryParse(id.split('_l').last) ?? 1;

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
      } catch (_) {}
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
    if (_progress.unlockedAchievements.contains(id)) return;

    final updated = List<String>.from(_progress.unlockedAchievements)..add(id);
    _progress = _progress.copyWith(unlockedAchievements: updated);
    await _saveProgress();
    notifyListeners();
  }

  // ─── Sandbox history ──────────────────────────────────────────────────────

  Future<void> addSandboxQuery(String sql) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('sandbox_history');
    List<String> history = [];
    if (existing != null) {
      final List<dynamic> list = jsonDecode(existing) as List<dynamic>;
      history = list.map((e) => e as String).toList();
    }
    history.insert(0, sql);
    if (history.length > 20) history = history.sublist(0, 20);
    await prefs.setString('sandbox_history', jsonEncode(history));
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
        // same day, no change
      } else if (diff == 1) {
        newStreak = _progress.currentStreak + 1;
      } else {
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

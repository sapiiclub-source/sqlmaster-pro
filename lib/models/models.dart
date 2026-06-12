import 'dart:convert';

class TheoryPage {
  final String type;
  final String title;
  final String content;
  final String? code;
  final String dialect;
  final String? keyConcept;

  const TheoryPage({
    required this.type,
    required this.title,
    required this.content,
    this.code,
    required this.dialect,
    this.keyConcept,
  });

  factory TheoryPage.fromJson(Map<String, dynamic> json) {
    return TheoryPage(
      type: json['type'] as String? ?? 'concept',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      code: json['code'] as String?,
      dialect: json['dialect'] as String? ?? 'generic',
      keyConcept: json['key_concept'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'content': content,
        if (code != null) 'code': code,
        'dialect': dialect,
        if (keyConcept != null) 'key_concept': keyConcept,
      };
}

class QuizQuestion {
  final String type;
  final String question;
  final String? code;
  final List<String> options;
  final dynamic correct;
  final String explanation;
  final int xp;

  const QuizQuestion({
    required this.type,
    required this.question,
    this.code,
    required this.options,
    required this.correct,
    required this.explanation,
    required this.xp,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final List<String> options = rawOptions is List
        ? rawOptions.map((e) => e.toString()).toList()
        : <String>[];

    final rawCorrect = json['correct'];
    dynamic correct;
    if (rawCorrect is int) {
      correct = rawCorrect;
    } else if (rawCorrect is String) {
      correct = rawCorrect;
    } else {
      correct = rawCorrect;
    }

    return QuizQuestion(
      type: json['type'] as String? ?? 'multiple_choice',
      question: json['question'] as String? ?? '',
      code: json['code'] as String?,
      options: options,
      correct: correct,
      explanation: json['explanation'] as String? ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'question': question,
        if (code != null) 'code': code,
        'options': options,
        'correct': correct,
        'explanation': explanation,
        'xp': xp,
      };
}

class Lesson {
  final String id;
  final String title;
  final int world;
  final String icon;
  final int xpReward;
  final String objective;
  final List<TheoryPage> theoryPages;
  final List<QuizQuestion> quizQuestions;

  const Lesson({
    required this.id,
    required this.title,
    required this.world,
    required this.icon,
    required this.xpReward,
    required this.objective,
    required this.theoryPages,
    required this.quizQuestions,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawTheory = json['theory_pages'] ?? json['theoryPages'];
    final List<TheoryPage> theoryPages = rawTheory is List
        ? rawTheory
            .map((e) => TheoryPage.fromJson(e as Map<String, dynamic>))
            .toList()
        : <TheoryPage>[];

    final rawQuiz = json['quiz_questions'] ?? json['quizQuestions'];
    final List<QuizQuestion> quizQuestions = rawQuiz is List
        ? rawQuiz
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList()
        : <QuizQuestion>[];

    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      world: (json['world'] as num?)?.toInt() ?? 1,
      icon: json['icon'] as String? ?? 'school',
      xpReward: (json['xp_reward'] ?? json['xpReward'] as num?)?.toInt() ?? 50,
      objective: json['objective'] as String? ?? '',
      theoryPages: theoryPages,
      quizQuestions: quizQuestions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'world': world,
        'icon': icon,
        'xp_reward': xpReward,
        'objective': objective,
        'theory_pages': theoryPages.map((e) => e.toJson()).toList(),
        'quiz_questions': quizQuestions.map((e) => e.toJson()).toList(),
      };
}

class UserProgress {
  int xp;
  int streak;
  int bestStreak;
  String lastPractice;
  Set<String> completedLessons;
  Map<String, int> lessonScores;
  Set<String> achievements;
  int sandboxQueriesCount;

  UserProgress({
    required this.xp,
    required this.streak,
    required this.bestStreak,
    required this.lastPractice,
    required this.completedLessons,
    required this.lessonScores,
    required this.achievements,
    required this.sandboxQueriesCount,
  });

  factory UserProgress.empty() {
    return UserProgress(
      xp: 0,
      streak: 0,
      bestStreak: 0,
      lastPractice: '',
      completedLessons: {},
      lessonScores: {},
      achievements: {},
      sandboxQueriesCount: 0,
    );
  }

  int get level => ((xp / 500).floor()).clamp(1, 50);

  int get xpToNextLevel => 500 - (xp % 500);

  double worldProgress(int world, List<Lesson> allLessons) {
    final worldLessons =
        allLessons.where((l) => l.world == world).toList();
    if (worldLessons.isEmpty) return 0.0;
    final completed =
        worldLessons.where((l) => completedLessons.contains(l.id)).length;
    return completed / worldLessons.length;
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streak': streak,
        'best_streak': bestStreak,
        'last_practice': lastPractice,
        'completed_lessons': completedLessons.toList(),
        'lesson_scores': lessonScores,
        'achievements': achievements.toList(),
        'sandbox_queries_count': sandboxQueriesCount,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final rawCompleted = json['completed_lessons'];
    final Set<String> completedLessons = rawCompleted is List
        ? rawCompleted.map((e) => e.toString()).toSet()
        : <String>{};

    final rawScores = json['lesson_scores'];
    final Map<String, int> lessonScores = rawScores is Map
        ? rawScores.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          )
        : <String, int>{};

    final rawAchievements = json['achievements'];
    final Set<String> achievements = rawAchievements is List
        ? rawAchievements.map((e) => e.toString()).toSet()
        : <String>{};

    return UserProgress(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      lastPractice: json['last_practice'] as String? ?? '',
      completedLessons: completedLessons,
      lessonScores: lessonScores,
      achievements: achievements,
      sandboxQueriesCount:
          (json['sandbox_queries_count'] as num?)?.toInt() ?? 0,
    );
  }
}
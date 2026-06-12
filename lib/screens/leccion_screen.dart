import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../state/app_state.dart';
import '../models/models.dart' hide Lesson, QuizQuestion, UserProgress;

// ---------------------------------------------------------------------------
// Phase enum
// ---------------------------------------------------------------------------

enum LeccionPhase { teoria, quiz, resultado }

// ---------------------------------------------------------------------------
// LeccionScreen
// ---------------------------------------------------------------------------

class LeccionScreen extends StatefulWidget {
  final AppState state;
  final String lessonId;

  const LeccionScreen({
    super.key,
    required this.state,
    required this.lessonId,
  });

  @override
  State<LeccionScreen> createState() => _LeccionScreenState();
}

class _LeccionScreenState extends State<LeccionScreen>
    with TickerProviderStateMixin {
  LeccionPhase _phase = LeccionPhase.teoria;

  // ── teoria state ──────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── quiz state ────────────────────────────────────────────────────────────
  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _correctCount = 0;
  int _xpEarned = 0;
  String _fillAnswer = '';
  final TextEditingController _fillController = TextEditingController();

  // ── resultado animation controllers ───────────────────────────────────────
  late final AnimationController _starsController;
  late final AnimationController _xpController;
  late final Animation<double> _starsAnim;
  late final Animation<double> _xpAnim;

  // ── helpers ───────────────────────────────────────────────────────────────
  Lesson? get _lesson => widget.state.lessonById(widget.lessonId);

  @override
  void initState() {
    super.initState();
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _starsAnim = CurvedAnimation(
      parent: _starsController,
      curve: Curves.elasticOut,
    );
    _xpAnim = CurvedAnimation(parent: _xpController, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fillController.dispose();
    _starsController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Root build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case LeccionPhase.teoria:
        return _buildTeoria();
      case LeccionPhase.quiz:
        return _buildQuiz();
      case LeccionPhase.resultado:
        return _buildResultado();
    }
  }

  // ===========================================================================
  // TEORIA PHASE
  // ===========================================================================

  Widget _buildTeoria() {
    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('Lección no encontrada',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final pages = lesson.questions.isEmpty ? <dynamic>[] : lesson.questions;
    // Use theoryContent split into paragraphs if no theoryPages available.
    // We build from available data based on the AppState Lesson model.
    final pageCount = _theorySectionCount(lesson);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lesson.title,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: pageCount > 0 ? (_currentPage + 1) / pageCount : 1.0,
            backgroundColor: AppColors.surfaceVariant,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageCount,
              itemBuilder: (ctx, i) => _buildTheoryPage(lesson, i),
            ),
          ),
          _buildTheoryNav(lesson, pageCount),
        ],
      ),
    );
  }

  int _theorySectionCount(Lesson lesson) {
    // We split the theory content into sections separated by double newlines
    final sections = _theoryPageSections(lesson);
    return sections.isEmpty ? 1 : sections.length;
  }

  List<Map<String, String>> _theoryPageSections(Lesson lesson) {
    final content = lesson.theoryContent;
    if (content.isEmpty) {
      return [
        {
          'type': 'concept',
          'title': lesson.title,
          'content': lesson.description,
        }
      ];
    }
    // Split on blank lines to create "pages"
    final blocks = content.split(RegExp(r'\n\s*\n'));
    return blocks.asMap().entries.map((e) {
      final text = e.value.trim();
      String type = 'concept';
      String title = lesson.title;
      String body = text;

      if (text.startsWith('## ')) {
        final lines = text.split('\n');
        title = lines.first.replaceFirst('## ', '').trim();
        body = lines.skip(1).join('\n').trim();
        type = 'concept';
      } else if (text.startsWith('### ')) {
        final lines = text.split('\n');
        title = lines.first.replaceFirst('### ', '').trim();
        body = lines.skip(1).join('\n').trim();
        type = 'example';
      } else if (text.startsWith('> ')) {
        type = 'tip';
        body = text.replaceAll('> ', '');
      } else if (text.startsWith('! ')) {
        type = 'warning';
        body = text.replaceFirst('! ', '');
      }

      if (e.key == 0 && title == lesson.title && body.isEmpty) {
        body = lesson.description;
      }

      return {'type': type, 'title': title, 'content': body};
    }).toList();
  }

  Widget _buildTheoryPage(Lesson lesson, int index) {
    final sections = _theoryPageSections(lesson);
    final section = index < sections.length
        ? sections[index]
        : {'type': 'concept', 'title': '', 'content': ''};

    final type = section['type'] ?? 'concept';
    final title = section['title'] ?? '';
    final content = section['content'] ?? '';

    // Check if content has a SQL code block (```sql ... ```)
    final codeRegex = RegExp(r'```(\w*)\n?([\s\S]*?)```');
    final codeMatch = codeRegex.firstMatch(content);
    String? codeSnippet;
    String? dialect;
    String displayContent = content;

    if (codeMatch != null) {
      dialect = codeMatch.group(1)?.toUpperCase() ?? 'SQL';
      codeSnippet = codeMatch.group(2)?.trim();
      displayContent = content.replaceAll(codeRegex, '').trim();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _typeChip(type),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayContent,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.65,
            ),
          ),
          if (codeSnippet != null && codeSnippet.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCodeBlock(codeSnippet, dialect ?? 'SQL'),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _typeChip(String type) {
    Color color;
    String label;

    switch (type) {
      case 'example':
        color = Colors.green;
        label = 'EJEMPLO';
        break;
      case 'tip':
        color = Colors.amber;
        label = 'TIP';
        break;
      case 'warning':
        color = Colors.red;
        label = 'ATENCIÓN';
        break;
      default:
        color = Colors.cyan;
        label = 'CONCEPTO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCodeBlock(String code, String dialect) {
    Color dialectColor;
    switch (dialect.toUpperCase()) {
      case 'SQL SERVER':
      case 'SQLSERVER':
        dialectColor = Colors.blue;
        break;
      case 'ORACLE':
        dialectColor = Colors.orange;
        break;
      default:
        dialectColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dialectColor.withOpacity(0.2),
                    border: Border.all(color: dialectColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dialect.isEmpty ? 'SQL' : dialect,
                    style: TextStyle(
                      color: dialectColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy,
                      color: Colors.white54, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Copiado!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheoryNav(Lesson lesson, int pageCount) {
    final isLast = _currentPage >= pageCount - 1;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (_currentPage > 0)
            OutlinedButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentPage--);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                foregroundColor: Colors.white,
              ),
              child: const Text('← Anterior'),
            ),
          const Spacer(),
          // Dots
          Row(
            children: List.generate(pageCount, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _currentPage
                      ? AppColors.primary
                      : Colors.grey.shade600,
                ),
              );
            }),
          ),
          const Spacer(),
          if (isLast)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _phase = LeccionPhase.quiz;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Comenzar Quiz →'),
            )
          else
            ElevatedButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentPage++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Siguiente →'),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // QUIZ PHASE
  // ===========================================================================

  Widget _buildQuiz() {
    final lesson = _lesson;
    if (lesson == null || lesson.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Quiz', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No hay preguntas disponibles.',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final questions = lesson.questions;
    final q = questions[_currentQuestion];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quiz',
          style: GoogleFonts.nunito(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                '${_currentQuestion + 1}/${questions.length}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary.withOpacity(0.25),
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimerBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuestionCard(q),
                  const SizedBox(height: 16),
                  if (q.codeSnippet != null && q.codeSnippet!.isNotEmpty) ...[
                    _buildCodeBlock(q.codeSnippet!, 'SQL'),
                    const SizedBox(height: 16),
                  ],
                  _buildMCOptions(q, questions),
                  if (_answered) ...[
                    const SizedBox(height: 16),
                    _buildExplanation(q),
                    const SizedBox(height: 16),
                    _buildNextButton(questions),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_currentQuestion),
      tween: Tween(begin: 1.0, end: 0.0),
      duration: const Duration(seconds: 45),
      builder: (ctx, value, _) {
        Color barColor;
        if (value > 0.5) {
          barColor = AppColors.success;
        } else if (value > 0.25) {
          barColor = AppColors.warning;
        } else {
          barColor = AppColors.error;
        }
        return LinearProgressIndicator(
          value: value,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(barColor),
          minHeight: 6,
        );
      },
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        q.question,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMCOptions(QuizQuestion q, List<QuizQuestion> questions) {
    return Column(
      children: List.generate(q.options.length, (i) {
        Color bgColor = AppColors.surfaceVariant;
        Color borderColor = Colors.transparent;
        double opacity = 1.0;

        if (_answered) {
          if (i == q.correctIndex) {
            bgColor = AppColors.success.withOpacity(0.3);
            borderColor = AppColors.success;
          } else if (i == _selectedAnswer && i != q.correctIndex) {
            bgColor = AppColors.error.withOpacity(0.3);
            borderColor = AppColors.error;
          } else {
            opacity = 0.5;
          }
        }

        return GestureDetector(
          onTap: _answered
              ? null
              : () {
                  setState(() {
                    _selectedAnswer = i;
                    _answered = true;
                    if (i == q.correctIndex) {
                      _correctCount++;
                    }
                  });
                },
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: borderColor == Colors.transparent
                        ? Colors.white12
                        : borderColor,
                    width: borderColor == Colors.transparent ? 1 : 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white10,
                    ),
                    child: Text(
                      String.fromCharCode(65 + i),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q.options[i],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                  ),
                  if (_answered && i == q.correctIndex)
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                  if (_answered &&
                      i == _selectedAnswer &&
                      i != q.correctIndex)
                    const Icon(Icons.cancel,
                        color: AppColors.error, size: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildExplanation(QuizQuestion q) {
    final isCorrect =
        _selectedAnswer != null && _selectedAnswer == q.correctIndex;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Colors.amber, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.explanation,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isCorrect)
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Text(
                  '¡Correcto! +${_lesson?.xpReward ?? 10} XP',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          else
            const Row(
              children: [
                Icon(Icons.cancel, color: AppColors.error, size: 16),
                SizedBox(width: 6),
                Text(
                  'Incorrecto',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNextButton(List<QuizQuestion> questions) {
    final isLast = _currentQuestion >= questions.length - 1;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLast ? _finishQuiz : _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          isLast ? 'Ver Resultados' : 'Siguiente →',
          style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion++;
      _selectedAnswer = null;
      _answered = false;
      _fillAnswer = '';
      _fillController.clear();
    });
  }

  void _finishQuiz() {
    final lesson = _lesson!;
    final questions = lesson.questions;
    final score = questions.isEmpty
        ? 0
        : (_correctCount / questions.length * 100).round();
    _xpEarned = lesson.xpReward + _correctCount * 20;
    widget.state.completeLesson(lesson.id, score, _xpEarned);
    setState(() {
      _phase = LeccionPhase.resultado;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _starsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _xpController.forward();
    });
  }

  // ===========================================================================
  // RESULTADO PHASE
  // ===========================================================================

  Widget _buildResultado() {
    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('Error', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final questions = lesson.questions;
    final total = questions.length;
    final pct = total > 0 ? _correctCount / total : 0.0;
    final int stars =
        pct >= 0.9 ? 3 : pct >= 0.7 ? 2 : 1;

    final String emoji =
        pct >= 0.8 ? '🏆' : pct >= 0.6 ? '⭐' : '💪';

    final String message = pct >= 0.9
        ? '¡Perfecto! Eres un crack 🔥'
        : pct >= 0.7
            ? '¡Muy bien! Sigue así 💪'
            : 'Sigue practicando, ¡tú puedes! 📚';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Emoji trophy
                Text(emoji,
                    style: const TextStyle(fontSize: 72)),

                const SizedBox(height: 16),

                Text(
                  '¡Lección Completada!',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),

                const SizedBox(height: 8),

                // Stars
                ScaleTransition(
                  scale: _starsAnim,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Icon(
                        Icons.star,
                        size: 40,
                        color: i < stars
                            ? AppColors.xpColor
                            : Colors.grey.shade700,
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 24),

                // Score card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_correctCount / $total correctas',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(pct * 100).round()}% de precisión',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // XP card
                ScaleTransition(
                  scale: _xpAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.xpColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.xpColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.xpColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '+$_xpEarned XP ganados',
                            style: GoogleFonts.nunito(
                              color: AppColors.xpColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Back to map button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Volver al Mapa',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                if (pct < 0.6) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetLesson,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Repetir lección',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetLesson() {
    _starsController.reset();
    _xpController.reset();
    setState(() {
      _phase = LeccionPhase.teoria;
      _currentPage = 0;
      _currentQuestion = 0;
      _selectedAnswer = null;
      _answered = false;
      _correctCount = 0;
      _xpEarned = 0;
      _fillAnswer = '';
      _fillController.clear();
    });
    _pageController.jumpToPage(0);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../providers/test_taking_provider.dart';
import '../widgets/answer_option_tile.dart';
import '../widgets/text_answer_field.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TEST TAKING SCREEN — Step 5
//
// Full-screen test experience:
//   • AppBar with test title
//   • Progress bar + question counter
//   • Question text
//   • Answer area (multiple-choice tiles OR text field)
//   • Prev / Next / Submit nav bar
//   • Result dialog on submit
// ═══════════════════════════════════════════════════════════════════════════

class TestTakingScreen extends StatelessWidget {
  final TestModel test;
  final String studentId;

  const TestTakingScreen({
    super.key,
    required this.test,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TestTakingProvider(test: test, studentId: studentId),
      child: const _TestTakingBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Body — consumes the provider
// ─────────────────────────────────────────────────────────────────────────

class _TestTakingBody extends StatefulWidget {
  const _TestTakingBody();

  @override
  State<_TestTakingBody> createState() => _TestTakingBodyState();
}

class _TestTakingBodyState extends State<_TestTakingBody> {
  // One controller per text-input question, keyed by questionId
  final Map<String, TextEditingController> _textControllers = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String questionId, String? initial) {
    return _textControllers.putIfAbsent(questionId, () {
      return TextEditingController(text: initial ?? '');
    });
  }

  // ── Submit handler ───────────────────────────────────────────────────
  Future<void> _onSubmit() async {
    final provider = context.read<TestTakingProvider>();

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          title: Text(
            'Submit Test?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
            ),
          ),
          content: Text(
            'You answered ${provider.answeredCount} of ${provider.totalQuestions} questions.\n\nAre you sure you want to submit?',
            style: TextStyle(
              color:
                  isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final result = await provider.submitTest();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Show result dialog
    await _showResultDialog(result);
  }

  Future<void> _showResultDialog(TestResultModel result) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          contentPadding: const EdgeInsets.all(AppSpacing.xxl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated score ring
              _ScoreRing(score: result.totalScore),
              const SizedBox(height: AppSpacing.xl),

              Text(
                _gradeLabel(result.totalScore),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _scoreColor(result.totalScore),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your score: ${result.totalScore}%',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Per-skill breakdown
              ...result.scores.entries
                  .where((e) => e.value > 0)
                  .map((e) => _SkillRow(
                        skill: _cap(e.key),
                        score: e.value,
                        isDark: isDark,
                      )),

              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx); // close dialog
                    Navigator.pop(context); // back to dashboard
                  },
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestTakingProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = provider.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.test.title,
          style: const TextStyle(fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Exit test',
          onPressed: () => _confirmExit(),
        ),
      ),
      body: Column(
        children: [
          // ── Progress section ────────────────────────────────────
          _ProgressHeader(
            current: provider.currentIndex + 1,
            total: provider.totalQuestions,
            progress: provider.progress,
            isDark: isDark,
          ),

          // ── Question + answers ─────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skill chip
                  _SkillChip(skill: question.skill, isDark: isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // Question text
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textPrimary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Answer area
                  _buildAnswerArea(provider, question, isDark),
                ],
              ),
            ),
          ),

          // ── Bottom nav ─────────────────────────────────────────
          _BottomNavBar(
            isFirst: provider.isFirst,
            isLast: provider.isLast,
            isSubmitting: _isSubmitting,
            onPrevious: provider.goPrevious,
            onNext: provider.goNext,
            onSubmit: _onSubmit,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Answer area builder ──────────────────────────────────────────────

  Widget _buildAnswerArea(
    TestTakingProvider provider,
    QuestionModel question,
    bool isDark,
  ) {
    if (question.type == QuestionType.multipleChoice) {
      final selected = provider.answerFor(question.id)?.selectedOption;
      const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

      return Column(
        children: List.generate(question.options!.length, (i) {
          final option = question.options![i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AnswerOptionTile(
              label: option,
              optionLetter: letters[i],
              isSelected: selected == option,
              onTap: () => provider.selectOption(question.id, option),
            ),
          );
        }),
      );
    }

    // Text input
    final existing = provider.answerFor(question.id)?.textAnswer;
    final controller = _controllerFor(question.id, existing);

    return TextAnswerField(
      controller: controller,
      onChanged: (text) => provider.setTextAnswer(question.id, text),
    );
  }

  // ── Exit confirmation ────────────────────────────────────────────────

  Future<void> _confirmExit() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'Exit Test?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
          ),
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: TextStyle(
            color:
                isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Continue Test',
              style: TextStyle(
                color: isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (exit == true && mounted) {
      Navigator.pop(context);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  static String _gradeLabel(int score) {
    if (score >= 90) return 'Excellent!';
    if (score >= 80) return 'Great Job!';
    if (score >= 70) return 'Good Work!';
    if (score >= 50) return 'Keep Practicing';
    return 'Needs Improvement';
  }

  static Color _scoreColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ═══════════════════════════════════════════════════════════════════════════
// PROGRESS HEADER — progress bar + question counter
// ═══════════════════════════════════════════════════════════════════════════

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final double progress;
  final bool isDark;

  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $current of $total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.primary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accent : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.dividerDark : AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SKILL CHIP — small label above question text
// ═══════════════════════════════════════════════════════════════════════════

class _SkillChip extends StatelessWidget {
  final String skill;
  final bool isDark;

  const _SkillChip({required this.skill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _skillColor(skill);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _cap(skill),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Color _skillColor(String skill) => switch (skill) {
        'listening' => AppColors.accent,
        'reading' => AppColors.success,
        'writing' => AppColors.warning,
        'speaking' => const Color(0xFF8B5CF6),
        'grammar' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM NAV BAR — Previous / Next / Submit
// ═══════════════════════════════════════════════════════════════════════════

class _BottomNavBar extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final bool isDark;

  const _BottomNavBar({
    required this.isFirst,
    required this.isLast,
    required this.isSubmitting,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isFirst ? null : onPrevious,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(
                    color: isFirst
                        ? (isDark ? AppColors.dividerDark : AppColors.divider)
                        : (isDark ? AppColors.accent : AppColors.primary),
                  ),
                  foregroundColor: isFirst
                      ? (isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textHint)
                      : (isDark ? AppColors.accent : AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Next / Submit button
            Expanded(
              child: isLast
                  ? FilledButton.icon(
                      onPressed: isSubmitting ? null : onSubmit,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(isSubmitting ? 'Submitting…' : 'Submit'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: onNext,
                      icon: const Text('Next'),
                      label: const Icon(Icons.arrow_forward_rounded, size: 18),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCORE RING — animated circular score in the result dialog
// ═══════════════════════════════════════════════════════════════════════════

class _ScoreRing extends StatefulWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _ringColor(widget.score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = (_animation.value * 100).round();
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _animation.value,
                  strokeWidth: 10,
                  backgroundColor: isDark
                      ? AppColors.dividerDark
                      : AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$value%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _ringColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SKILL ROW — single skill score bar in the result dialog
// ═══════════════════════════════════════════════════════════════════════════

class _SkillRow extends StatelessWidget {
  final String skill;
  final int score;
  final bool isDark;

  const _SkillRow({
    required this.skill,
    required this.score,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = _barColor(score);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              skill,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 8,
                backgroundColor:
                    isDark ? AppColors.dividerDark : AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 36,
            child: Text(
              '$score%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _barColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }
}

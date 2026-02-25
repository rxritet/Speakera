import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../providers/theme_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/risk_badge.dart';
import '../widgets/skill_bar_chart.dart';
import 'test_taking_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// STUDENT DASHBOARD — Step 4
//
// Sections (scrollable):
//   1. Welcome header with greeting + avatar
//   2. Stat cards: Average Score · Best Skill · Tests Taken · Risk Level
//   3. SkillBarChart — aggregate bar chart across all results
//   4. Test History — list of completed tests with dates & scores
// ═══════════════════════════════════════════════════════════════════════════

class StudentDashboard extends StatelessWidget {
  final String studentId;
  final VoidCallback onLogout;

  const StudentDashboard({
    super.key,
    required this.studentId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final student = getStudentById(studentId);
    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Dashboard')),
        body: const Center(child: Text('Student not found')),
      );
    }

    final results = getResultsByStudent(studentId);

    // ── Computed KPIs ──
    final avgScore = results.isEmpty
        ? 0
        : (results.fold<int>(0, (s, r) => s + r.totalScore) / results.length)
            .round();

    final aggregatedScores = _aggregateScores(results);

    String bestSkill = '—';
    int bestVal = 0;
    for (final entry in aggregatedScores.entries) {
      if (entry.value > bestVal) {
        bestVal = entry.value;
        bestSkill = _cap(entry.key);
      }
    }

    final latestRisk = results.isNotEmpty ? results.last.riskLevel : null;

    return Scaffold(
      appBar: _buildAppBar(context, student, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 ── Welcome section ──────────────────────────────
            _WelcomeSection(
              student: student,
              avgScore: avgScore,
              bestSkill: bestSkill,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2 ── Stat cards ───────────────────────────────────
            _buildStatCards(
              context,
              avgScore: avgScore,
              bestSkill: bestSkill,
              testsTaken: results.length,
              latestRisk: latestRisk,
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3 ── Available Tests ──────────────────────────────
            _buildAvailableTests(context, studentId, isDark),
            const SizedBox(height: AppSpacing.xl),

            // 4 ── Skills bar chart ─────────────────────────────
            SkillBarChart(scores: aggregatedScores),
            const SizedBox(height: AppSpacing.xl),

            // 5 ── Test History ─────────────────────────────────
            _buildTestHistorySection(context, results, isDark),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // AppBar
  // ────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, UserModel student, bool isDark) {
    return AppBar(
      title: Text('Hi, ${student.name.split(' ').first}!'),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
          onPressed: onLogout,
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Stat cards row / grid
  // ────────────────────────────────────────────────────────────

  Widget _buildStatCards(
    BuildContext context, {
    required int avgScore,
    required String bestSkill,
    required int testsTaken,
    required RiskLevel? latestRisk,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    final cards = [
      StatCard(
        title: 'Avg Score',
        value: '$avgScore',
        icon: Icons.trending_up_rounded,
        iconColor: AppColors.accent,
      ),
      StatCard(
        title: 'Best Skill',
        value: bestSkill,
        icon: Icons.star_rounded,
        iconColor: AppColors.warning,
      ),
      StatCard(
        title: 'Tests Taken',
        value: '$testsTaken',
        icon: Icons.quiz_rounded,
        iconColor: AppColors.success,
      ),
      StatCard(
        title: 'Risk Level',
        value: latestRisk != null ? _cap(latestRisk.name) : '—',
        icon: Icons.shield_rounded,
        iconColor: latestRisk != null
            ? _riskColor(latestRisk)
            : AppColors.textHint,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.1,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        children: cards,
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Available Tests
  // ────────────────────────────────────────────────────────────

  Widget _buildAvailableTests(
    BuildContext context,
    String studentId,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    // Show active tests that have questions
    final available = mockTests
        .where((t) => t.status == TestStatus.active && t.questions.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Tests',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (available.isEmpty)
          _emptyState(isDark, 'No tests available right now')
        else
          ...available.map(
            (test) => _AvailableTestCard(
              test: test,
              studentId: studentId,
              isDark: isDark,
            ),
          ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Test History
  // ────────────────────────────────────────────────────────────

  Widget _buildTestHistorySection(
    BuildContext context,
    List<TestResultModel> results,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (results.isEmpty)
          _emptyState(isDark, 'No tests completed yet')
        else
          ...results.reversed.map((r) => _TestHistoryCard(result: r, isDark: isDark)),
      ],
    );
  }

  Widget _emptyState(bool isDark, String message) {
    return Card(
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: isDark
            ? BorderSide(color: AppColors.dividerDark.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.huge, horizontal: AppSpacing.lg),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color:
                  isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────

  /// Average each skill across all results (ignoring 0-score entries).
  static Map<String, int> _aggregateScores(List<TestResultModel> results) {
    const skills = ['listening', 'reading', 'writing', 'speaking', 'grammar'];
    final sums = <String, int>{};
    final counts = <String, int>{};

    for (final r in results) {
      for (final skill in skills) {
        final val = r.scores[skill] ?? 0;
        if (val > 0) {
          sums[skill] = (sums[skill] ?? 0) + val;
          counts[skill] = (counts[skill] ?? 0) + 1;
        }
      }
    }

    return {
      for (final skill in skills)
        skill: counts.containsKey(skill)
            ? (sums[skill]! / counts[skill]!).round()
            : 0,
    };
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static Color _riskColor(RiskLevel level) => switch (level) {
        RiskLevel.low => AppColors.riskLow,
        RiskLevel.medium => AppColors.riskMedium,
        RiskLevel.high => AppColors.riskHigh,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// AVAILABLE TEST CARD — tappable card to start a test
// ═══════════════════════════════════════════════════════════════════════════

class _AvailableTestCard extends StatelessWidget {
  final TestModel test;
  final String studentId;
  final bool isDark;

  const _AvailableTestCard({
    required this.test,
    required this.studentId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = switch (test.type) {
      TestType.placement => 'Placement',
      TestType.progress => 'Progress',
      TestType.mock => 'Mock Exam',
    };

    return Card(
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: isDark
            ? BorderSide(color: AppColors.dividerDark.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TestTakingScreen(
                test: test,
                studentId: studentId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Test type icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title + info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$typeLabel · ${test.questions.length} questions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Start arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.accent : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isDark ? AppColors.accent : AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WELCOME SECTION — gradient card with greeting, score ring & best skill
// ═══════════════════════════════════════════════════════════════════════════

class _WelcomeSection extends StatelessWidget {
  final UserModel student;
  final int avgScore;
  final String bestSkill;
  final bool isDark;

  const _WelcomeSection({
    required this.student,
    required this.avgScore,
    required this.bestSkill,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.primaryDark, AppColors.surfaceDark]
              : [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Left: greeting text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  student.name.split(' ').first,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Best skill chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Best: $bestSkill',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Right: score ring ──
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: avgScore / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _ringColor(avgScore),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$avgScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'avg',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _ringColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accentLight;
    return AppColors.riskHigh;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST HISTORY CARD — single result row with date, score, risk & skills
// ═══════════════════════════════════════════════════════════════════════════

class _TestHistoryCard extends StatefulWidget {
  final TestResultModel result;
  final bool isDark;

  const _TestHistoryCard({required this.result, required this.isDark});

  @override
  State<_TestHistoryCard> createState() => _TestHistoryCardState();
}

class _TestHistoryCardState extends State<_TestHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isDark = widget.isDark;
    final testTitle = getTestTitle(r.testId);
    final dateStr = DateFormat('MMM d, yyyy').format(r.completedDate);

    return Card(
      elevation: isDark ? 0 : 1,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: isDark
            ? BorderSide(color: AppColors.dividerDark.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──
              Row(
                children: [
                  // Test icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.assignment_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Title + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score
                  Text(
                    '${r.totalScore}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(r.totalScore),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Expand chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // ── Risk badge row ──
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.sm, left: 50),
                child: RiskBadge(riskScore: r.riskLevel, dense: true),
              ),

              // ── Expandable skills breakdown ──
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildBreakdown(r, isDark),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdown(TestResultModel r, bool isDark) {
    final entries =
        r.scores.entries.where((e) => e.value > 0).toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...entries.map((e) {
              final color = _barColor(e.value);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Text(
                        _cap(e.key),
                        style: TextStyle(
                          fontSize: 12,
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
                          value: e.value / 100,
                          backgroundColor: isDark
                              ? AppColors.dividerDark
                              : AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${e.value}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }

  static Color _barColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

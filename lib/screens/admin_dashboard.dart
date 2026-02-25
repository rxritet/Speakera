import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../providers/theme_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/kpi_chart.dart';
import '../widgets/risk_badge.dart';
import '../widgets/filter_chips.dart' as fc;

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN DASHBOARD — Step 3
//
// 4-tab layout: Overview · Students · Tests · Results
// Responsive: BottomNavigationBar on mobile, NavigationRail on desktop (≥768).
// Uses AppColors / AppSpacing / AppRadius everywhere.
// ═══════════════════════════════════════════════════════════════════════════

class AdminDashboard extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminDashboard({super.key, required this.onLogout});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 0;

  // ── Students tab state ──
  String _studentSearch = '';
  String _riskFilter = 'All';

  // ── Tests tab state ──
  String _testFilter = 'All';

  // ── Results tab state ──
  String? _expandedResultId;

  // ─────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _navIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────
  // Computed helpers
  // ─────────────────────────────────────────────────────

  int get _avgScore {
    if (mockResults.isEmpty) return 0;
    final total = mockResults.fold<int>(0, (sum, r) => sum + r.totalScore);
    return (total / mockResults.length).round();
  }

  int get _activeTestCount =>
      mockTests.where((t) => t.status == TestStatus.active).length;

  int get _completedResultCount =>
      mockResults.where((r) => r.status == ResultStatus.completed).length;

  int get _highRiskCount =>
      mockResults.where((r) => r.riskLevel == RiskLevel.high).length;

  List<UserModel> get _filteredStudents {
    var list = mockStudents.toList();
    if (_studentSearch.isNotEmpty) {
      final q = _studentSearch.toLowerCase();
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q))
          .toList();
    }
    if (_riskFilter != 'All') {
      final level = RiskLevel.values.firstWhere(
        (l) => l.name == _riskFilter.toLowerCase(),
        orElse: () => RiskLevel.low,
      );
      // Keep students that have at least one result with the selected risk
      final idsWithRisk = mockResults
          .where((r) => r.riskLevel == level)
          .map((r) => r.studentId)
          .toSet();
      list = list.where((s) => idsWithRisk.contains(s.id)).toList();
    }
    return list;
  }

  List<TestModel> get _filteredTests {
    if (_testFilter == 'All') return mockTests;
    final type = TestType.values.firstWhere(
      (t) => t.name == _testFilter.toLowerCase(),
      orElse: () => TestType.placement,
    );
    return mockTests.where((t) => t.type == type).toList();
  }

  // ─────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────

  void _onNavSelected(int i) {
    setState(() {
      _navIndex = i;
      _tabController.animateTo(i);
    });
  }

  static const _destinations =
      <({IconData icon, IconData activeIcon, String label})>[
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Overview'
    ),
    (
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Students'
    ),
    (icon: Icons.quiz_outlined, activeIcon: Icons.quiz, label: 'Tests'),
    (
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment,
      label: 'Results'
    ),
  ];

  // ─────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(isDark),
      body: isMobile
          ? _buildBody(isMobile, isDark)
          : Row(
              children: [
                _buildNavigationRail(isDark),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildBody(false, isDark)),
              ],
            ),
      bottomNavigationBar: isMobile ? _buildBottomNav(isDark) : null,
    );
  }

  // ─────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      title: const Text('Speakera Admin'),
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
          onPressed: widget.onLogout,
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // Bottom Navigation Bar (mobile)
  // ─────────────────────────────────────────────────────

  Widget _buildBottomNav(bool isDark) {
    return NavigationBar(
      selectedIndex: _navIndex,
      onDestinationSelected: _onNavSelected,
      destinations: _destinations
          .map((d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: d.label,
              ))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────
  // Navigation Rail (desktop)
  // ─────────────────────────────────────────────────────

  Widget _buildNavigationRail(bool isDark) {
    return NavigationRail(
      selectedIndex: _navIndex,
      onDestinationSelected: _onNavSelected,
      labelType: NavigationRailLabelType.all,
      leading: const SizedBox(height: AppSpacing.sm),
      destinations: _destinations
          .map((d) => NavigationRailDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: Text(d.label),
              ))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────
  // Body — TabBarView
  // ─────────────────────────────────────────────────────

  Widget _buildBody(bool isMobile, bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        _OverviewTab(
          isMobile: isMobile,
          isDark: isDark,
          avgScore: _avgScore,
          activeTests: _activeTestCount,
          completedResults: _completedResultCount,
          highRisk: _highRiskCount,
        ),
        _buildStudentsTab(isDark),
        _buildTestsTab(isDark),
        _buildResultsTab(isDark),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2 — Students
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStudentsTab(bool isDark) {
    final students = _filteredStudents;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──
          Text(
            'Students',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Search bar ──
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _studentSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _studentSearch = ''),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _studentSearch = v),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Risk filter chips ──
          fc.FilterChips<String>(
            options: const ['All', 'Low', 'Medium', 'High'],
            selected: _riskFilter,
            labelBuilder: (s) => s == 'All' ? 'All' : '$s Risk',
            onSelected: (v) => setState(() => _riskFilter = v),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Student list ──
          Expanded(
            child: Card(
              elevation: isDark ? 0 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: isDark
                    ? BorderSide(
                        color: AppColors.dividerDark.withValues(alpha: 0.5))
                    : BorderSide.none,
              ),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 48,
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textHint),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No students found',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: students.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 72,
                        color:
                            isDark ? AppColors.dividerDark : AppColors.divider,
                      ),
                      itemBuilder: (context, i) =>
                          _buildStudentTile(students[i], isDark),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(UserModel s, bool isDark) {
    // Find latest result for this student to show risk badge
    final results = getResultsByStudent(s.id);
    final latestResult = results.isNotEmpty ? results.last : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          s.name[0],
          style: const TextStyle(
              color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(
        s.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        s.email,
        style: TextStyle(
          fontSize: 13,
          color:
              isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
        ),
      ),
      trailing: latestResult != null
          ? RiskBadge(riskScore: latestResult.riskLevel, dense: true)
          : null,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${s.name}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3 — Tests
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildTestsTab(bool isDark) {
    final tests = _filteredTests;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),

          fc.FilterChips<String>(
            options: const ['All', 'Placement', 'Progress', 'Mock'],
            selected: _testFilter,
            labelBuilder: (s) => s,
            onSelected: (v) => setState(() => _testFilter = v),
          ),
          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: Card(
              elevation: isDark ? 0 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: isDark
                    ? BorderSide(
                        color: AppColors.dividerDark.withValues(alpha: 0.5))
                    : BorderSide.none,
              ),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: tests.isEmpty
                  ? Center(
                      child: Text(
                        'No tests found',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: tests.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color:
                            isDark ? AppColors.dividerDark : AppColors.divider,
                      ),
                      itemBuilder: (context, i) =>
                          _buildTestTile(tests[i], isDark),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTile(TestModel t, bool isDark) {
    final statusConf = _statusConf(t.status);
    final typeConf = _typeConf(t.type);
    final progress =
        t.assignedCount > 0 ? t.completedCount / t.assignedCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with chips
          Row(
            children: [
              Expanded(
                child: Text(
                  t.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _chipBadge(typeConf.label, typeConf.color),
              const SizedBox(width: 4),
              _chipBadge(statusConf.label, statusConf.color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Skills
          Text(
            'Skills: ${t.skills.join(", ")}',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        isDark ? AppColors.dividerDark : AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppColors.success : AppColors.accent,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${t.completedCount}/${t.assignedCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textDarkSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4 — Results (expandable)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildResultsTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Card(
              elevation: isDark ? 0 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: isDark
                    ? BorderSide(
                        color: AppColors.dividerDark.withValues(alpha: 0.5))
                    : BorderSide.none,
              ),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: mockResults.isEmpty
                  ? Center(
                      child: Text(
                        'No results yet',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: mockResults.length,
                      itemBuilder: (context, i) {
                        final r = mockResults[i];
                        final isExpanded = _expandedResultId == r.id;
                        return _buildResultTile(r, isExpanded, isDark);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(TestResultModel r, bool isExpanded, bool isDark) {
    final studentName = getStudentName(r.studentId);
    final testTitle = getTestTitle(r.testId);
    final statusConf = _resultStatusConf(r.status);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 2),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              studentName[0],
              style: const TextStyle(
                  color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      testTitle,
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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _scoreColor(r.totalScore),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                RiskBadge(riskScore: r.riskLevel, dense: true),
                const SizedBox(width: AppSpacing.sm),
                _chipBadge(statusConf.label, statusConf.color),
              ],
            ),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.expand_more),
          ),
          onTap: () {
            setState(() {
              _expandedResultId = isExpanded ? null : r.id;
            });
          },
        ),

        // ── Expandable skills breakdown ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildSkillsBreakdown(r, isDark),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),

        Divider(
          height: 1,
          indent: 72,
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ],
    );
  }

  Widget _buildSkillsBreakdown(TestResultModel r, bool isDark) {
    // Filter out skills with score 0 (not tested)
    final entries = r.scores.entries.where((e) => e.value > 0).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
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
              final color = _skillBarColor(e.value);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: Text(
                        _capitalise(e.key),
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

  // ═══════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════════

  Widget _chipBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }

  Color _skillBarColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  // ── Status / type config records ──

  ({String label, Color color}) _statusConf(TestStatus s) => switch (s) {
        TestStatus.active => (label: 'Active', color: AppColors.success),
        TestStatus.draft => (label: 'Draft', color: AppColors.textHint),
        TestStatus.archived => (label: 'Archived', color: AppColors.info),
      };

  ({String label, Color color}) _typeConf(TestType t) => switch (t) {
        TestType.placement =>
          (label: 'Placement', color: const Color(0xFF8B5CF6)),
        TestType.progress => (label: 'Progress', color: AppColors.accent),
        TestType.mock => (label: 'Mock', color: AppColors.warning),
      };

  ({String label, Color color}) _resultStatusConf(ResultStatus s) =>
      switch (s) {
        ResultStatus.completed =>
          (label: 'Completed', color: AppColors.success),
        ResultStatus.inProgress =>
          (label: 'In Progress', color: AppColors.warning),
        ResultStatus.pending => (label: 'Pending', color: AppColors.textHint),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 1 — Overview (extracted as stateless widget for clarity)
// ═══════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  final int avgScore;
  final int activeTests;
  final int completedResults;
  final int highRisk;

  const _OverviewTab({
    required this.isMobile,
    required this.isDark,
    required this.avgScore,
    required this.activeTests,
    required this.completedResults,
    required this.highRisk,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Section title ──
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── KPI stat cards ──
        _buildStatCards(),
        const SizedBox(height: AppSpacing.lg),

        // ── KPI chart ──
        KpiChart(data: weeklyKpiData),
        const SizedBox(height: AppSpacing.lg),

        // ── Risk Distribution ──
        _buildRiskDistribution(context),
        const SizedBox(height: AppSpacing.lg),

        // ── Recent Results ──
        _buildRecentResults(context),
      ],
    );
  }

  Widget _buildStatCards() {
    final cards = [
      StatCard(
        title: 'Total Students',
        value: '${mockStudents.length}',
        icon: Icons.people,
        iconColor: AppColors.accent,
        subtitle: '${mockStudents.length} enrolled',
      ),
      StatCard(
        title: 'Active Tests',
        value: '$activeTests',
        icon: Icons.quiz,
        iconColor: AppColors.success,
        subtitle: '${mockTests.length} total',
      ),
      StatCard(
        title: 'Completed',
        value: '$completedResults',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.warning,
        subtitle: '${mockResults.length} total results',
      ),
      StatCard(
        title: 'Avg Score',
        value: '$avgScore',
        icon: Icons.trending_up,
        iconColor: avgScore >= 70 ? AppColors.riskLow : AppColors.riskHigh,
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

  Widget _buildRiskDistribution(BuildContext context) {
    final theme = Theme.of(context);
    final total =
        riskLevelDistribution.values.fold<int>(0, (a, b) => a + b);

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: isDark
            ? BorderSide(color: AppColors.dividerDark.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...riskLevelDistribution.entries.map((e) {
              final percent = total > 0 ? e.value / total : 0.0;
              final conf = _riskConf(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: conf.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 70,
                      child: Text(
                        conf.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: isDark
                              ? AppColors.dividerDark
                              : AppColors.divider,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(conf.color),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${e.value}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textSecondary,
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

  Widget _buildRecentResults(BuildContext context) {
    final theme = Theme.of(context);
    final recent = mockResults.take(5).toList();

    return Card(
      elevation: isDark ? 0 : 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: isDark
            ? BorderSide(color: AppColors.dividerDark.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...recent.map((r) {
              final name = getStudentName(r.studentId);
              final test = getTestTitle(r.testId);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        name[0],
                        style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            test,
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
                    RiskBadge(riskScore: r.riskLevel, dense: true),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${r.totalScore}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _scoreColor(r.totalScore),
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

  // ── helpers ──

  static Color _scoreColor(int score) {
    if (score >= 80) return AppColors.riskLow;
    if (score >= 60) return AppColors.accent;
    return AppColors.riskHigh;
  }

  static ({String label, Color color}) _riskConf(RiskLevel level) =>
      switch (level) {
        RiskLevel.low => (label: 'Low', color: AppColors.riskLow),
        RiskLevel.medium => (label: 'Medium', color: AppColors.riskMedium),
        RiskLevel.high => (label: 'High', color: AppColors.riskHigh),
      };
}

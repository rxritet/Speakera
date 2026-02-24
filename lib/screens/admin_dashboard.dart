import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../widgets/stat_card.dart';
import '../widgets/kpi_chart.dart';
import '../widgets/risk_badge.dart';
import '../widgets/filter_chips.dart' as fc;

class AdminDashboard extends StatefulWidget {
  final VoidCallback onLogout;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const AdminDashboard({
    super.key,
    required this.onLogout,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  // Students tab state
  String _studentSearch = '';
  String _riskFilter = 'All';

  // Tests tab state
  String _testFilter = 'All';

  // Results tab state
  String? _expandedResultId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _bottomNavIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Computed values
  int get _avgScore {
    if (mockResults.isEmpty) return 0;
    final total = mockResults.fold<int>(0, (sum, r) => sum + r.score);
    return (total / mockResults.length).round();
  }

  List<Student> get _filteredStudents {
    var list = mockStudents.toList();
    if (_studentSearch.isNotEmpty) {
      final q = _studentSearch.toLowerCase();
      list = list
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_riskFilter != 'All') {
      final risk = RiskScore.values.firstWhere(
        (r) => r.name == _riskFilter.toLowerCase(),
      );
      list = list.where((s) => s.riskScore == risk).toList();
    }
    return list;
  }

  List<Test> get _filteredTests {
    if (_testFilter == 'All') return mockTests;
    final type = TestType.values.firstWhere(
      (t) => t.name == _testFilter.toLowerCase(),
    );
    return mockTests.where((t) => t.type == type).toList();
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Speakera Admin',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        Tooltip(
          message: widget.isDarkMode ? 'Light Mode' : 'Dark Mode',
          child: Switch(
            value: widget.isDarkMode,
            onChanged: widget.onThemeToggle,
            thumbIcon: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.dark_mode, size: 16);
              }
              return const Icon(Icons.light_mode, size: 16);
            }),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: widget.onLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildContentArea(bool isMobile, bool isDark) {
    return Column(
      children: [
        // Summary cards + chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildSummaryCards(isMobile),
              const SizedBox(height: 12),
              KpiChart(data: weeklyKpiData),
            ],
          ),
        ),
        // Tabs content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudentsTab(isDark),
              _buildTestsTab(isDark),
              _buildResultsTab(isDark),
            ],
          ),
        ),
      ],
    );
  }

  void _onNavDestinationSelected(int i) {
    setState(() {
      _bottomNavIndex = i;
      _tabController.animateTo(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isMobile) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: _buildContentArea(true, isDark),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _bottomNavIndex,
          onDestinationSelected: _onNavDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Students',
            ),
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz),
              label: 'Tests',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'Results',
            ),
          ],
        ),
      );
    }

    // ── Desktop layout: NavigationRail on the left ──────────────
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _bottomNavIndex,
            onDestinationSelected: _onNavDestinationSelected,
            labelType: NavigationRailLabelType.all,
            leading: const SizedBox(height: 8),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Students'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz),
                label: Text('Tests'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assessment_outlined),
                selectedIcon: Icon(Icons.assessment),
                label: Text('Results'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _buildContentArea(false, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    final cards = [
      const StatCard(
        title: 'Total Students',
        value: '5',
        icon: Icons.people,
        iconColor: Color(0xFF3B82F6),
      ),
      const StatCard(
        title: 'Active Tests',
        value: '2',
        icon: Icons.quiz,
        iconColor: Color(0xFF10B981),
      ),
      const StatCard(
        title: 'Completed Results',
        value: '3',
        icon: Icons.check_circle,
        iconColor: Color(0xFFF59E0B),
      ),
      StatCard(
        title: 'Avg Score',
        value: '$_avgScore',
        icon: Icons.trending_up,
        iconColor: const Color(0xFFEF4444),
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: cards,
      );
    }

    return Row(children: cards.map((c) => Expanded(child: c)).toList());
  }

  // ─── Students Tab ─────────────────────────────────────────────
  Widget _buildStudentsTab(bool isDark) {
    final students = _filteredStudents;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _studentSearch = v),
          ),
          const SizedBox(height: 12),
          fc.FilterChips<String>(
            options: const ['All', 'Low', 'Medium', 'High'],
            selected: _riskFilter,
            labelBuilder: (s) => s == 'All' ? 'All' : '$s Risk',
            onSelected: (v) {
              setState(() => _riskFilter = v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Filter: $v Risk'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: students.isEmpty
                  ? const Center(child: Text('No students found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = students[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E3A5F),
                            child: Text(
                              s.name[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${s.email}  •  ${s.group}  •  ${s.level}',
                          ),
                          trailing: RiskBadge(riskScore: s.riskScore),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Selected: ${s.name}'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tests Tab ────────────────────────────────────────────────
  Widget _buildTestsTab(bool isDark) {
    final tests = _filteredTests;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          fc.FilterChips<String>(
            options: const ['All', 'Placement', 'Progress', 'Mock'],
            selected: _testFilter,
            labelBuilder: (s) => s,
            onSelected: (v) {
              setState(() => _testFilter = v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Filter: $v'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: tests.isEmpty
                  ? const Center(child: Text('No tests found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: tests.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final t = tests[i];
                        return _buildTestTile(t, isDark);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTile(Test t, bool isDark) {
    Color statusColor;
    switch (t.status) {
      case TestStatus.active:
        statusColor = Colors.green;
        break;
      case TestStatus.draft:
        statusColor = Colors.grey;
        break;
      case TestStatus.archived:
        statusColor = Colors.blue;
        break;
    }

    Color typeColor;
    switch (t.type) {
      case TestType.placement:
        typeColor = const Color(0xFF8B5CF6);
        break;
      case TestType.progress:
        typeColor = const Color(0xFF3B82F6);
        break;
      case TestType.mock:
        typeColor = const Color(0xFFF59E0B);
        break;
    }

    final progress = t.assignedCount > 0
        ? t.completedCount / t.assignedCount
        : 0.0;

    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              t.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              t.type.name,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            backgroundColor: typeColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          Chip(
            label: Text(
              t.status.name,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            backgroundColor: statusColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(
            'Skills: ${t.skills.join(", ")}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : const Color(0xFF3B82F6),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${t.completedCount}/${t.assignedCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opened: ${t.title}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  // ─── Results Tab ──────────────────────────────────────────────
  Widget _buildResultsTab(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: mockResults.isEmpty
            ? const Center(child: Text('No results found'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: mockResults.length,
                itemBuilder: (context, i) {
                  final r = mockResults[i];
                  final isExpanded = _expandedResultId == r.id;
                  return _buildResultTile(r, isExpanded, isDark);
                },
              ),
      ),
    );
  }

  Widget _buildResultTile(TestResult r, bool isExpanded, bool isDark) {
    final studentName = getStudentName(r.studentId);
    final testTitle = getTestTitle(r.testId);

    Color statusColor;
    switch (r.status) {
      case ResultStatus.completed:
        statusColor = Colors.green;
        break;
      case ResultStatus.inProgress:
        statusColor = Colors.orange;
        break;
      case ResultStatus.pending:
        statusColor = Colors.grey;
        break;
    }

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF1E3A5F),
            child: Text(
              studentName[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      testTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${r.score}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text('Level: ${r.level}', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                RiskBadge(riskScore: r.riskScore),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    r.status.name,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: statusColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          onTap: () {
            setState(() {
              _expandedResultId = isExpanded ? null : r.id;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isExpanded ? 'Collapsed' : 'Expanded: $studentName',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
        // Expandable skills breakdown
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Card(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skills Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...r.skillsBreakdown.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 70,
                              child: Text(
                                e.key[0].toUpperCase() + e.key.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: e.value / 100,
                                  backgroundColor: isDark
                                      ? Colors.white12
                                      : Colors.grey[200],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF3B82F6),
                                      ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${e.value}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

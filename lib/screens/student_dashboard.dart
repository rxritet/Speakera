import 'package:flutter/material.dart';
import '../models/models.dart';
import '../data/mock_data.dart';
import '../widgets/stat_card.dart';
import '../widgets/kpi_chart.dart';
import '../widgets/risk_badge.dart';

class StudentDashboard extends StatelessWidget {
  final String studentId;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const StudentDashboard({
    super.key,
    required this.studentId,
    required this.onLogout,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final student = mockStudents.firstWhere((s) => s.id == studentId);
    final results = mockResults.where((r) => r.studentId == studentId).toList();
    final avgScore = results.isEmpty
        ? 0
        : (results.fold<int>(0, (sum, r) => sum + r.score) / results.length)
              .round();

    // Find best skill across all results
    String bestSkill = '—';
    int bestVal = 0;
    for (final r in results) {
      for (final entry in r.skillsBreakdown.entries) {
        if (entry.value > bestVal) {
          bestVal = entry.value;
          bestSkill = entry.key[0].toUpperCase() + entry.key.substring(1);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${student.name.split(' ').first}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Tooltip(
            message: isDarkMode ? 'Light Mode' : 'Dark Mode',
            child: Switch(
              value: isDarkMode,
              onChanged: onThemeToggle,
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
            onPressed: onLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal stat cards
            _buildPersonalStats(context, student, avgScore, bestSkill),
            const SizedBox(height: 16),

            // KPI chart
            KpiChart(data: weeklyKpiData),
            const SizedBox(height: 16),

            // My results
            Text(
              'My Test Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 12),
            if (results.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No test results yet')),
                ),
              )
            else
              ...results.map((r) => _buildResultCard(context, r, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalStats(
    BuildContext context,
    Student student,
    int avgScore,
    String bestSkill,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final cards = [
      StatCard(
        title: 'Avg Score',
        value: '$avgScore',
        icon: Icons.trending_up,
        iconColor: const Color(0xFF3B82F6),
      ),
      StatCard(
        title: 'Best Skill',
        value: bestSkill,
        icon: Icons.star,
        iconColor: const Color(0xFFF59E0B),
      ),
      StatCard(
        title: 'Level',
        value: student.level,
        icon: Icons.school,
        iconColor: const Color(0xFF10B981),
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
        children: [
          ...cards,
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Risk', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  RiskBadge(riskScore: student.riskScore),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        ...cards.map((c) => Expanded(child: c)),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Risk Level', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  RiskBadge(riskScore: student.riskScore),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, TestResult r, bool isDark) {
    final testTitle = getTestTitle(r.testId);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    testTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${r.score}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Level: ${r.level}', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                RiskBadge(riskScore: r.riskScore),
              ],
            ),
            const SizedBox(height: 12),
            // Skills breakdown bars
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
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
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
                          valueColor: const AlwaysStoppedAnimation<Color>(
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
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
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
}

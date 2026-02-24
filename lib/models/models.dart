enum UserRole { admin, student }

enum RiskScore { low, medium, high }

enum TestType { placement, progress, mock }

enum TestStatus { active, draft, archived }

enum ResultStatus { completed, inProgress, pending }

class Student {
  final String id;
  final String name;
  final String email;
  final String group;
  final String level;
  final RiskScore riskScore;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.group,
    required this.level,
    required this.riskScore,
  });
}

class Test {
  final String id;
  final String title;
  final String date;
  final TestType type;
  final TestStatus status;
  final List<String> skills;
  final int assignedCount;
  final int completedCount;

  const Test({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.status,
    required this.skills,
    required this.assignedCount,
    required this.completedCount,
  });
}

class TestResult {
  final String id;
  final String studentId;
  final String testId;
  final String level;
  final String date;
  final int score;
  final RiskScore riskScore;
  final ResultStatus status;
  final Map<String, int> skillsBreakdown;

  const TestResult({
    required this.id,
    required this.studentId,
    required this.testId,
    required this.level,
    required this.date,
    required this.score,
    required this.riskScore,
    required this.status,
    required this.skillsBreakdown,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum UserRole { admin, student }

enum RiskLevel { low, medium, high }

/// @deprecated Use [RiskLevel] instead. Kept for backward compatibility.
typedef RiskScore = RiskLevel;

enum TestStatus { active, draft, archived }

enum ResultStatus { completed, inProgress, pending }

enum TestType { placement, progress, mock }

enum QuestionType { multipleChoice, textInput }

// ═══════════════════════════════════════════════════════════════════════════
// USER MODEL
// ═══════════════════════════════════════════════════════════════════════════

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      role.hashCode ^
      avatarUrl.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST MODEL
// ═══════════════════════════════════════════════════════════════════════════

class TestModel {
  final String id;
  final String title;
  final DateTime date;
  final TestStatus status;
  final TestType type;
  final List<String> skills;
  final int assignedCount;
  final int completedCount;
  final List<QuestionModel> questions;

  const TestModel({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.type,
    required this.skills,
    required this.assignedCount,
    required this.completedCount,
    this.questions = const [],
  });

  TestModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    TestStatus? status,
    TestType? type,
    List<String>? skills,
    int? assignedCount,
    int? completedCount,
    List<QuestionModel>? questions,
  }) {
    return TestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      skills: skills ?? this.skills,
      assignedCount: assignedCount ?? this.assignedCount,
      completedCount: completedCount ?? this.completedCount,
      questions: questions ?? this.questions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          date == other.date &&
          status == other.status &&
          type == other.type &&
          skills == other.skills &&
          assignedCount == other.assignedCount &&
          completedCount == other.completedCount;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      date.hashCode ^
      status.hashCode ^
      type.hashCode ^
      skills.hashCode ^
      assignedCount.hashCode ^
      completedCount.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════
// QUESTION MODEL
// ═══════════════════════════════════════════════════════════════════════════

class QuestionModel {
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options;
  final String correctAnswer;
  final String skill; // listening, reading, writing, speaking, grammar

  const QuestionModel({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    required this.correctAnswer,
    required this.skill,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// STUDENT ANSWER MODEL
// ═══════════════════════════════════════════════════════════════════════════

class StudentAnswerModel {
  final String questionId;
  final String? selectedOption;
  final String? textAnswer;

  const StudentAnswerModel({
    required this.questionId,
    this.selectedOption,
    this.textAnswer,
  });

  /// Returns the answer text regardless of question type.
  String get answer => selectedOption ?? textAnswer ?? '';
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST RESULT MODEL
// ═══════════════════════════════════════════════════════════════════════════

class TestResultModel {
  final String id;
  final String studentId;
  final String testId;
  final Map<String, int> scores; // Listening, Reading, Writing, Speaking, Grammar
  final int totalScore;
  final RiskLevel riskLevel;
  final ResultStatus status;
  final DateTime completedDate;

  const TestResultModel({
    required this.id,
    required this.studentId,
    required this.testId,
    required this.scores,
    required this.totalScore,
    required this.riskLevel,
    required this.status,
    required this.completedDate,
  });

  TestResultModel copyWith({
    String? id,
    String? studentId,
    String? testId,
    Map<String, int>? scores,
    int? totalScore,
    RiskLevel? riskLevel,
    ResultStatus? status,
    DateTime? completedDate,
  }) {
    return TestResultModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      testId: testId ?? this.testId,
      scores: scores ?? this.scores,
      totalScore: totalScore ?? this.totalScore,
      riskLevel: riskLevel ?? this.riskLevel,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestResultModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          studentId == other.studentId &&
          testId == other.testId &&
          scores == other.scores &&
          totalScore == other.totalScore &&
          riskLevel == other.riskLevel &&
          status == other.status &&
          completedDate == other.completedDate;

  @override
  int get hashCode =>
      id.hashCode ^
      studentId.hashCode ^
      testId.hashCode ^
      scores.hashCode ^
      totalScore.hashCode ^
      riskLevel.hashCode ^
      status.hashCode ^
      completedDate.hashCode;
}

// ═══════════════════════════════════════════════════════════════════════════
// LEGACY MODELS (for backward compatibility)
// ═══════════════════════════════════════════════════════════════════════════

class Student {
  final String id;
  final String name;
  final String email;
  final String group;
  final String level;
  final RiskLevel riskScore;

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
  final RiskLevel riskScore;
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

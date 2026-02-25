import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

/// TestTakingProvider manages the state of test-in-progress:
///   - current question index
///   - student answers
///   - scoring & result creation on submit
class TestTakingProvider extends ChangeNotifier {
  final TestModel test;
  final String studentId;

  TestTakingProvider({required this.test, required this.studentId});

  // ── State ────────────────────────────────────────────────────────────
  int _currentIndex = 0;
  final Map<String, StudentAnswerModel> _answers = {};
  bool _submitted = false;
  TestResultModel? _result;

  // ── Getters ──────────────────────────────────────────────────────────
  int get currentIndex => _currentIndex;
  int get totalQuestions => test.questions.length;
  bool get isFirst => _currentIndex == 0;
  bool get isLast => _currentIndex == totalQuestions - 1;
  double get progress => totalQuestions > 0
      ? (_currentIndex + 1) / totalQuestions
      : 0;
  bool get submitted => _submitted;
  TestResultModel? get result => _result;

  QuestionModel get currentQuestion => test.questions[_currentIndex];

  /// Returns the student's answer for a given question, or null.
  StudentAnswerModel? answerFor(String questionId) => _answers[questionId];

  /// How many questions have been answered.
  int get answeredCount => _answers.length;

  // ── Navigation ───────────────────────────────────────────────────────

  void goNext() {
    if (_currentIndex < totalQuestions - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void goPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void goTo(int index) {
    if (index >= 0 && index < totalQuestions) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // ── Answer handling ──────────────────────────────────────────────────

  void selectOption(String questionId, String option) {
    _answers[questionId] = StudentAnswerModel(
      questionId: questionId,
      selectedOption: option,
    );
    notifyListeners();
  }

  void setTextAnswer(String questionId, String text) {
    _answers[questionId] = StudentAnswerModel(
      questionId: questionId,
      textAnswer: text,
    );
    notifyListeners();
  }

  // ── Submit & Score ───────────────────────────────────────────────────

  /// Scores the test and creates a TestResultModel.
  /// Returns the created result.
  Future<TestResultModel> submitTest() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Count correct answers per skill
    final skillCorrect = <String, int>{};
    final skillTotal = <String, int>{};

    for (final q in test.questions) {
      skillTotal[q.skill] = (skillTotal[q.skill] ?? 0) + 1;

      final answer = _answers[q.id];
      if (answer != null) {
        if (q.type == QuestionType.multipleChoice) {
          if (answer.selectedOption == q.correctAnswer) {
            skillCorrect[q.skill] = (skillCorrect[q.skill] ?? 0) + 1;
          }
        } else {
          // Text input — award points if the student wrote something
          if ((answer.textAnswer ?? '').trim().isNotEmpty) {
            skillCorrect[q.skill] = (skillCorrect[q.skill] ?? 0) + 1;
          }
        }
      }
    }

    // Build per-skill scores (0–100)
    const allSkills = ['listening', 'reading', 'writing', 'speaking', 'grammar'];
    final scores = <String, int>{};
    for (final skill in allSkills) {
      final total = skillTotal[skill] ?? 0;
      final correct = skillCorrect[skill] ?? 0;
      scores[skill] = total > 0 ? ((correct / total) * 100).round() : 0;
    }

    // Overall score
    final answeredSkills = scores.entries.where((e) => e.value > 0).toList();
    final totalScore = answeredSkills.isEmpty
        ? 0
        : (answeredSkills.fold<int>(0, (s, e) => s + e.value) /
                answeredSkills.length)
            .round();

    // Risk level
    final risk = totalScore >= 70
        ? RiskLevel.low
        : totalScore >= 50
            ? RiskLevel.medium
            : RiskLevel.high;

    final newResult = TestResultModel(
      id: 'r${mockResults.length + 1}',
      studentId: studentId,
      testId: test.id,
      scores: scores,
      totalScore: totalScore,
      riskLevel: risk,
      status: ResultStatus.completed,
      completedDate: DateTime.now(),
    );

    // Persist into mock data
    mockResults.add(newResult);

    _submitted = true;
    _result = newResult;
    notifyListeners();

    return newResult;
  }
}

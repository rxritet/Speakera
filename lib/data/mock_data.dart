import '../models/models.dart';

final List<Student> mockStudents = [
  const Student(
    id: 's1',
    name: 'Alice Johnson',
    email: 'alice@example.com',
    group: 'Advanced A',
    level: 'B2',
    riskScore: RiskScore.low,
  ),
  const Student(
    id: 's2',
    name: 'Bob Smith',
    email: 'bob@example.com',
    group: 'Intermediate B',
    level: 'B1',
    riskScore: RiskScore.medium,
  ),
  const Student(
    id: 's3',
    name: 'Charlie Brown',
    email: 'charlie@example.com',
    group: 'Advanced A',
    level: 'C1',
    riskScore: RiskScore.low,
  ),
  const Student(
    id: 's4',
    name: 'Diana Prince',
    email: 'diana@example.com',
    group: 'Beginner A',
    level: 'A2',
    riskScore: RiskScore.high,
  ),
  const Student(
    id: 's5',
    name: 'Evan Wright',
    email: 'evan@example.com',
    group: 'Intermediate B',
    level: 'B1',
    riskScore: RiskScore.low,
  ),
];

final List<Test> mockTests = [
  const Test(
    id: 't1',
    title: 'Mid-Term Progress Check',
    date: '2023-10-15',
    type: TestType.progress,
    status: TestStatus.active,
    skills: ['speaking', 'writing'],
    assignedCount: 24,
    completedCount: 18,
  ),
  const Test(
    id: 't2',
    title: 'Placement Test 2024',
    date: '2023-11-01',
    type: TestType.placement,
    status: TestStatus.active,
    skills: ['grammar', 'reading', 'listening'],
    assignedCount: 150,
    completedCount: 45,
  ),
  const Test(
    id: 't3',
    title: 'Mock Exam: B2 First',
    date: '2023-12-10',
    type: TestType.mock,
    status: TestStatus.draft,
    skills: ['speaking', 'writing', 'reading', 'listening', 'grammar'],
    assignedCount: 0,
    completedCount: 0,
  ),
];

final List<TestResult> mockResults = [
  const TestResult(
    id: 'r1',
    studentId: 's1',
    testId: 't1',
    level: 'B2',
    date: '2023-10-15',
    score: 82,
    riskScore: RiskScore.low,
    status: ResultStatus.completed,
    skillsBreakdown: {'speaking': 85, 'writing': 78, 'grammar': 83},
  ),
  const TestResult(
    id: 'r2',
    studentId: 's2',
    testId: 't1',
    level: 'B1',
    date: '2023-10-15',
    score: 65,
    riskScore: RiskScore.medium,
    status: ResultStatus.completed,
    skillsBreakdown: {'speaking': 60, 'writing': 70, 'grammar': 65},
  ),
  const TestResult(
    id: 'r3',
    studentId: 's4',
    testId: 't1',
    level: 'A2',
    date: '2023-10-15',
    score: 45,
    riskScore: RiskScore.high,
    status: ResultStatus.completed,
    skillsBreakdown: {'speaking': 40, 'writing': 50, 'grammar': 45},
  ),
];

final List<double> weeklyKpiData = [65, 68, 72, 70, 74, 78, 80];

final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String getStudentName(String studentId) {
  final student = mockStudents.firstWhere(
    (s) => s.id == studentId,
    orElse: () => const Student(
      id: '',
      name: 'Unknown',
      email: '',
      group: '',
      level: '',
      riskScore: RiskScore.low,
    ),
  );
  return student.name;
}

String getTestTitle(String testId) {
  final test = mockTests.firstWhere(
    (t) => t.id == testId,
    orElse: () => const Test(
      id: '',
      title: 'Unknown',
      date: '',
      type: TestType.placement,
      status: TestStatus.draft,
      skills: [],
      assignedCount: 0,
      completedCount: 0,
    ),
  );
  return test.title;
}

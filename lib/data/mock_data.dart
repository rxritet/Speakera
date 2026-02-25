import '../models/models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN USERS
// ═══════════════════════════════════════════════════════════════════════════

final List<UserModel> mockAdmins = [
  const UserModel(
    id: 'a1',
    name: 'Elena Rodriguez',
    email: 'elena.rodriguez@speakera.com',
    role: UserRole.admin,
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
  ),
  const UserModel(
    id: 'a2',
    name: 'John Mitchell',
    email: 'john.mitchell@speakera.com',
    role: UserRole.admin,
    avatarUrl: 'https://i.pravatar.cc/150?img=2',
  ),
  const UserModel(
    id: 'a3',
    name: 'Sarah Thompson',
    email: 'sarah.thompson@speakera.com',
    role: UserRole.admin,
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// STUDENT USERS
// ═══════════════════════════════════════════════════════════════════════════

final List<UserModel> mockStudents = [
  const UserModel(
    id: 's1',
    name: 'Alice Johnson',
    email: 'alice.johnson@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=10',
  ),
  const UserModel(
    id: 's2',
    name: 'Bob Smith',
    email: 'bob.smith@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=11',
  ),
  const UserModel(
    id: 's3',
    name: 'Charlie Brown',
    email: 'charlie.brown@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
  ),
  const UserModel(
    id: 's4',
    name: 'Diana Prince',
    email: 'diana.prince@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=13',
  ),
  const UserModel(
    id: 's5',
    name: 'Evan Wright',
    email: 'evan.wright@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=14',
  ),
  const UserModel(
    id: 's6',
    name: 'Fiona Green',
    email: 'fiona.green@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=15',
  ),
  const UserModel(
    id: 's7',
    name: 'George Harris',
    email: 'george.harris@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=16',
  ),
  const UserModel(
    id: 's8',
    name: 'Hannah Wilson',
    email: 'hannah.wilson@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=17',
  ),
  const UserModel(
    id: 's9',
    name: 'Ivan Anderson',
    email: 'ivan.anderson@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=18',
  ),
  const UserModel(
    id: 's10',
    name: 'Julia Martinez',
    email: 'julia.martinez@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=19',
  ),
  const UserModel(
    id: 's11',
    name: 'Kevin Taylor',
    email: 'kevin.taylor@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=20',
  ),
  const UserModel(
    id: 's12',
    name: 'Laura White',
    email: 'laura.white@student.com',
    role: UserRole.student,
    avatarUrl: 'https://i.pravatar.cc/150?img=21',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════

final List<TestModel> mockTests = [
  TestModel(
    id: 't1',
    title: 'Mid-Term Progress Check',
    date: DateTime(2026, 2, 15),
    type: TestType.progress,
    status: TestStatus.active,
    skills: ['speaking', 'writing', 'listening'],
    assignedCount: 24,
    completedCount: 18,
    questions: const [
      QuestionModel(
        id: 'q1_1',
        text: 'Which word best completes the sentence?\n\n"She ___ to the store every morning before work."',
        type: QuestionType.multipleChoice,
        options: ['go', 'goes', 'going', 'gone'],
        correctAnswer: 'goes',
        skill: 'grammar',
      ),
      QuestionModel(
        id: 'q1_2',
        text: 'Listen to the description. What is the speaker mainly talking about?',
        type: QuestionType.multipleChoice,
        options: [
          'A holiday trip to France',
          'Daily routines at work',
          'A new restaurant in town',
          'Weekend plans with friends',
        ],
        correctAnswer: 'Daily routines at work',
        skill: 'listening',
      ),
      QuestionModel(
        id: 'q1_3',
        text: 'Choose the correct meaning of the idiom:\n\n"It\'s raining cats and dogs."',
        type: QuestionType.multipleChoice,
        options: [
          'Animals are falling from the sky',
          'It is raining very heavily',
          'The weather is unpredictable',
          'Pets are running outside',
        ],
        correctAnswer: 'It is raining very heavily',
        skill: 'reading',
      ),
      QuestionModel(
        id: 'q1_4',
        text: 'Write 2-3 sentences describing your favourite hobby and explain why you enjoy it.',
        type: QuestionType.textInput,
        correctAnswer: '',
        skill: 'writing',
      ),
      QuestionModel(
        id: 'q1_5',
        text: 'Which sentence uses the Present Perfect correctly?',
        type: QuestionType.multipleChoice,
        options: [
          'I have went to Paris last summer.',
          'She has been living here since 2020.',
          'They has finished the project.',
          'He have seen that movie twice.',
        ],
        correctAnswer: 'She has been living here since 2020.',
        skill: 'grammar',
      ),
      QuestionModel(
        id: 'q1_6',
        text: 'Read the passage and choose the main idea:\n\n"Remote work has transformed the modern workplace. Employees now have greater flexibility, but companies face new challenges in maintaining team cohesion."',
        type: QuestionType.multipleChoice,
        options: [
          'Remote work has only negative effects',
          'Remote work has both benefits and challenges',
          'Companies should ban remote work',
          'Employees prefer working in offices',
        ],
        correctAnswer: 'Remote work has both benefits and challenges',
        skill: 'reading',
      ),
      QuestionModel(
        id: 'q1_7',
        text: 'Describe in a few sentences what you would say to introduce yourself at a job interview.',
        type: QuestionType.textInput,
        correctAnswer: '',
        skill: 'speaking',
      ),
      QuestionModel(
        id: 'q1_8',
        text: 'Choose the correct word to complete the sentence:\n\n"The meeting was ___ because everyone shared great ideas."',
        type: QuestionType.multipleChoice,
        options: ['boring', 'productive', 'confusing', 'silent'],
        correctAnswer: 'productive',
        skill: 'listening',
      ),
    ],
  ),
  TestModel(
    id: 't2',
    title: 'Placement Test 2026',
    date: DateTime(2026, 1, 1),
    type: TestType.placement,
    status: TestStatus.active,
    skills: ['grammar', 'reading', 'listening', 'speaking'],
    assignedCount: 150,
    completedCount: 125,
    questions: const [
      QuestionModel(
        id: 'q2_1',
        text: 'Choose the correct form:\n\n"If I ___ rich, I would travel the world."',
        type: QuestionType.multipleChoice,
        options: ['am', 'was', 'were', 'be'],
        correctAnswer: 'were',
        skill: 'grammar',
      ),
      QuestionModel(
        id: 'q2_2',
        text: 'What does "break the ice" mean?',
        type: QuestionType.multipleChoice,
        options: [
          'To literally break frozen water',
          'To start a conversation in a social setting',
          'To end a friendship',
          'To solve a difficult problem',
        ],
        correctAnswer: 'To start a conversation in a social setting',
        skill: 'reading',
      ),
      QuestionModel(
        id: 'q2_3',
        text: 'Select the sentence with correct word order:',
        type: QuestionType.multipleChoice,
        options: [
          'Always she drinks coffee in the morning.',
          'She always drinks coffee in the morning.',
          'She drinks always coffee in the morning.',
          'In the morning always she drinks coffee.',
        ],
        correctAnswer: 'She always drinks coffee in the morning.',
        skill: 'grammar',
      ),
      QuestionModel(
        id: 'q2_4',
        text: 'Write a short paragraph about what you did last weekend (3-4 sentences).',
        type: QuestionType.textInput,
        correctAnswer: '',
        skill: 'writing',
      ),
      QuestionModel(
        id: 'q2_5',
        text: 'Which word is a synonym of "happy"?',
        type: QuestionType.multipleChoice,
        options: ['Sad', 'Joyful', 'Angry', 'Tired'],
        correctAnswer: 'Joyful',
        skill: 'reading',
      ),
      QuestionModel(
        id: 'q2_6',
        text: 'Choose the correct preposition:\n\n"She is interested ___ learning new languages."',
        type: QuestionType.multipleChoice,
        options: ['on', 'at', 'in', 'for'],
        correctAnswer: 'in',
        skill: 'grammar',
      ),
    ],
  ),
  TestModel(
    id: 't3',
    title: 'Mock Exam: B2 First Certificate',
    date: DateTime(2026, 3, 10),
    type: TestType.mock,
    status: TestStatus.draft,
    skills: ['speaking', 'writing', 'reading', 'listening', 'grammar'],
    assignedCount: 0,
    completedCount: 0,
  ),
  TestModel(
    id: 't4',
    title: 'Listening Skills Assessment',
    date: DateTime(2026, 2, 20),
    type: TestType.progress,
    status: TestStatus.archived,
    skills: ['listening'],
    assignedCount: 50,
    completedCount: 50,
  ),
  TestModel(
    id: 't5',
    title: 'Writing Workshop Evaluation',
    date: DateTime(2026, 2, 25),
    type: TestType.progress,
    status: TestStatus.active,
    skills: ['writing', 'grammar'],
    assignedCount: 32,
    completedCount: 28,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// TEST RESULTS
// ═══════════════════════════════════════════════════════════════════════════

final List<TestResultModel> mockResults = [
  TestResultModel(
    id: 'r1',
    studentId: 's1',
    testId: 't1',
    scores: {
      'listening': 85,
      'reading': 88,
      'writing': 82,
      'speaking': 86,
      'grammar': 89,
    },
    totalScore: 86,
    riskLevel: RiskLevel.low,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 15),
  ),
  TestResultModel(
    id: 'r2',
    studentId: 's2',
    testId: 't1',
    scores: {
      'listening': 68,
      'reading': 72,
      'writing': 70,
      'speaking': 65,
      'grammar': 71,
    },
    totalScore: 69,
    riskLevel: RiskLevel.medium,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 16),
  ),
  TestResultModel(
    id: 'r3',
    studentId: 's3',
    testId: 't1',
    scores: {
      'listening': 92,
      'reading': 95,
      'writing': 90,
      'speaking': 93,
      'grammar': 96,
    },
    totalScore: 93,
    riskLevel: RiskLevel.low,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 15),
  ),
  TestResultModel(
    id: 'r4',
    studentId: 's4',
    testId: 't1',
    scores: {
      'listening': 45,
      'reading': 48,
      'writing': 42,
      'speaking': 44,
      'grammar': 46,
    },
    totalScore: 45,
    riskLevel: RiskLevel.high,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 17),
  ),
  TestResultModel(
    id: 'r5',
    studentId: 's5',
    testId: 't1',
    scores: {
      'listening': 78,
      'reading': 81,
      'writing': 76,
      'speaking': 79,
      'grammar': 80,
    },
    totalScore: 79,
    riskLevel: RiskLevel.low,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 18),
  ),
  TestResultModel(
    id: 'r6',
    studentId: 's6',
    testId: 't1',
    scores: {
      'listening': 60,
      'reading': 62,
      'writing': 58,
      'speaking': 61,
      'grammar': 63,
    },
    totalScore: 61,
    riskLevel: RiskLevel.medium,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 19),
  ),
  TestResultModel(
    id: 'r7',
    studentId: 's7',
    testId: 't2',
    scores: {
      'listening': 75,
      'reading': 78,
      'writing': 72,
      'speaking': 76,
      'grammar': 79,
    },
    totalScore: 76,
    riskLevel: RiskLevel.low,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 1, 15),
  ),
  TestResultModel(
    id: 'r8',
    studentId: 's8',
    testId: 't2',
    scores: {
      'listening': 55,
      'reading': 58,
      'writing': 52,
      'speaking': 54,
      'grammar': 57,
    },
    totalScore: 55,
    riskLevel: RiskLevel.medium,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 1, 20),
  ),
  TestResultModel(
    id: 'r9',
    studentId: 's9',
    testId: 't2',
    scores: {
      'listening': 42,
      'reading': 44,
      'writing': 40,
      'speaking': 41,
      'grammar': 43,
    },
    totalScore: 42,
    riskLevel: RiskLevel.high,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 1, 25),
  ),
  TestResultModel(
    id: 'r10',
    studentId: 's10',
    testId: 't2',
    scores: {
      'listening': 88,
      'reading': 90,
      'writing': 86,
      'speaking': 89,
      'grammar': 91,
    },
    totalScore: 89,
    riskLevel: RiskLevel.low,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 1, 18),
  ),
  TestResultModel(
    id: 'r11',
    studentId: 's11',
    testId: 't4',
    scores: {
      'listening': 82,
      'reading': 0,
      'writing': 0,
      'speaking': 0,
      'grammar': 0,
    },
    totalScore: 82,
    riskLevel: RiskLevel.low,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 20),
  ),
  TestResultModel(
    id: 'r12',
    studentId: 's12',
    testId: 't4',
    scores: {
      'listening': 58,
      'reading': 0,
      'writing': 0,
      'speaking': 0,
      'grammar': 0,
    },
    totalScore: 58,
    riskLevel: RiskLevel.medium,
    status: ResultStatus.completed,
    completedDate: DateTime(2026, 2, 20),
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// HELPER DATA FOR CHARTS
// ═══════════════════════════════════════════════════════════════════════════

final List<double> weeklyKpiData = [65, 68, 72, 70, 74, 78, 80];

final List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

final Map<RiskLevel, int> riskLevelDistribution = {
  RiskLevel.low: 7,
  RiskLevel.medium: 3,
  RiskLevel.high: 2,
};

// ═══════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

String getStudentName(String studentId) {
  final student = mockStudents.firstWhere(
    (s) => s.id == studentId,
    orElse: () => const UserModel(
      id: '',
      name: 'Unknown',
      email: '',
      role: UserRole.student,
    ),
  );
  return student.name;
}

String getTestTitle(String testId) {
  final test = mockTests.firstWhere(
    (t) => t.id == testId,
    orElse: () => TestModel(
      id: '',
      title: 'Unknown',
      date: DateTime.now(),
      type: TestType.placement,
      status: TestStatus.draft,
      skills: [],
      assignedCount: 0,
      completedCount: 0,
    ),
  );
  return test.title;
}

UserModel? getAdminById(String adminId) {
  try {
    return mockAdmins.firstWhere((a) => a.id == adminId);
  } catch (e) {
    return null;
  }
}

UserModel? getStudentById(String studentId) {
  try {
    return mockStudents.firstWhere((s) => s.id == studentId);
  } catch (e) {
    return null;
  }
}

TestModel? getTestById(String testId) {
  try {
    return mockTests.firstWhere((t) => t.id == testId);
  } catch (e) {
    return null;
  }
}

List<TestResultModel> getResultsByStudent(String studentId) {
  return mockResults.where((r) => r.studentId == studentId).toList();
}

List<TestResultModel> getResultsByTest(String testId) {
  return mockResults.where((r) => r.testId == testId).toList();
}

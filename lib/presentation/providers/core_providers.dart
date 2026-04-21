import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/firebase/habitduel_firestore_store.dart';
import '../../data/datasources/firebase_aware_data_sources.dart';
import '../../data/repositories/auth_repo_impl.dart';
import '../../data/repositories/duel_repo_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/duel_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/checkins/checkin_usecase.dart';
import '../../domain/usecases/duels/accept_duel_usecase.dart';
import '../../domain/usecases/duels/create_duel_usecase.dart';
import '../../domain/usecases/duels/get_duel_detail_usecase.dart';
import '../../domain/usecases/duels/get_my_duels_usecase.dart';

// ─── Инфраструктурные провайдеры ───────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final firestoreStoreProvider = Provider<HabitDuelFirestoreStore>((ref) {
  return HabitDuelFirestoreStore();
});

// ─── Auth — теперь полностью Firebase Auth ─────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(secureStorageProvider),
    ref.watch(firestoreStoreProvider),
  );
});

// ─── Use cases аутентификации ──────────────────────────────────────────

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// ─── Провайдеры данных дуэлей ──────────────────────────────────────────
// Используем FirebaseAwareDuelDataSource — Firestore primary, REST fallback.

final duelRemoteDSProvider = Provider<FirebaseAwareDuelDataSource>((ref) {
  return FirebaseAwareDuelDataSource(
    ref.watch(secureStorageProvider),
    ref.watch(firestoreStoreProvider),
  );
});

final duelRepositoryProvider = Provider<DuelRepository>((ref) {
  return DuelRepositoryImpl(
    ref.watch(duelRemoteDSProvider),
    ref.watch(firestoreStoreProvider),
  );
});

// ─── Use cases дуэлей ──────────────────────────────────────────────────

final createDuelUseCaseProvider = Provider<CreateDuelUseCase>((ref) {
  return CreateDuelUseCase(ref.watch(duelRepositoryProvider));
});

final acceptDuelUseCaseProvider = Provider<AcceptDuelUseCase>((ref) {
  return AcceptDuelUseCase(ref.watch(duelRepositoryProvider));
});

final getMyDuelsUseCaseProvider = Provider<GetMyDuelsUseCase>((ref) {
  return GetMyDuelsUseCase(ref.watch(duelRepositoryProvider));
});

final getDuelDetailUseCaseProvider = Provider<GetDuelDetailUseCase>((ref) {
  return GetDuelDetailUseCase(ref.watch(duelRepositoryProvider));
});

final checkInUseCaseProvider = Provider<CheckInUseCase>((ref) {
  return CheckInUseCase(ref.watch(duelRepositoryProvider));
});

// ─── Leaderboard / Profile ─────────────────────────────────────────────

final leaderboardRemoteDSProvider =
    Provider<FirebaseAwareLeaderboardDataSource>((ref) {
  return FirebaseAwareLeaderboardDataSource(
    ref.watch(firestoreStoreProvider),
  );
});

final profileRemoteDSProvider = Provider<FirebaseAwareProfileDataSource>((ref) {
  return FirebaseAwareProfileDataSource(
    ref.watch(secureStorageProvider),
    ref.watch(firestoreStoreProvider),
  );
});

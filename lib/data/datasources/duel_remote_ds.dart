import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../models/duel_model.dart';

/// Handles raw HTTP calls to /duels/* endpoints.
class DuelRemoteDataSource {
  const DuelRemoteDataSource(this._dio);
  final Dio _dio;

  /// POST /duels
  Future<DuelModel> createDuel({
    required String habitName,
    String? description,
    required int durationDays,
    String? opponentUsername,
  }) async {
    try {
      final response = await _dio.post('/duels', data: {
        'habit_name': habitName,
        if (description != null) 'description': description,
        'duration_days': durationDays,
        if (opponentUsername != null) 'opponent_username': opponentUsername,
      });
      return DuelModel.fromCreateJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /duels/:id/accept
  Future<DuelModel> acceptDuel(String duelId) async {
    try {
      final response = await _dio.post('/duels/$duelId/accept');
      final data = response.data as Map<String, dynamic>;
      return DuelModel(
        id: data['id'] as String,
        habitName: '',
        status: data['status'] as String,
        durationDays: 0,
        startsAt: data['starts_at'] != null
            ? DateTime.parse(data['starts_at'] as String)
            : null,
        endsAt: data['ends_at'] != null
            ? DateTime.parse(data['ends_at'] as String)
            : null,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /duels
  Future<List<DuelModel>> getMyDuels() async {
    try {
      final response = await _dio.get('/duels');
      final data = response.data as Map<String, dynamic>;
      final list = data['duels'] as List<dynamic>;
      return list
          .map((j) => DuelModel.fromListJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /duels/:id
  Future<DuelModel> getDuelDetail(String duelId) async {
    try {
      final response = await _dio.get('/duels/$duelId');
      return DuelModel.fromDetailJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// POST /duels/:id/checkin
  Future<Map<String, dynamic>> checkIn(String duelId, {String? note}) async {
    try {
      final response = await _dio.post(
        '/duels/$duelId/checkin',
        data: {if (note != null) 'note': note},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Failure _mapError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Server error';
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      message = data['error'] as String;
    }
    switch (statusCode) {
      case 403:
        return ServerFailure(message, statusCode: 403);
      case 404:
        return ServerFailure(message, statusCode: 404);
      case 409:
        return ServerFailure(message, statusCode: 409);
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          return const NetworkFailure();
        }
        return ServerFailure(message, statusCode: statusCode);
    }
  }
}

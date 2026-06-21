import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_rating.dart';

class RatingRepository {
  final DioClient _dioClient;

  RatingRepository(this._dioClient);

  Future<List<RateableUser>> getUsersToRate() async {
    try {
      final response = await _dioClient.dio.get('/ratings/users');
      return (response.data as List)
          .map((json) => RateableUser.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> submitRating(int rateeId, double rating) async {
    try {
      // Sending bypassSaturday=true for testing purposes. In production, remove this query param.
      await _dioClient.dio.post('/ratings?bypassSaturday=true', data: {
        'rateeId': rateeId,
        'rating': rating,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AdminRatingSummary>> getAdminRatingsSummary() async {
    try {
      final response = await _dioClient.dio.get('/ratings/admin-summary');
      return (response.data as List)
          .map((json) => AdminRatingSummary.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      return error.response?.data?['message'] ?? error.message ?? 'An error occurred';
    }
    return error.toString();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/rating_repository.dart';
import '../../domain/user_rating.dart';

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RatingRepository(dioClient);
});

final usersToRateProvider = FutureProvider.autoDispose<List<RateableUser>>((ref) {
  final repository = ref.watch(ratingRepositoryProvider);
  return repository.getUsersToRate();
});

final adminRatingsSummaryProvider = FutureProvider.autoDispose<List<AdminRatingSummary>>((ref) {
  final repository = ref.watch(ratingRepositoryProvider);
  return repository.getAdminRatingsSummary();
});

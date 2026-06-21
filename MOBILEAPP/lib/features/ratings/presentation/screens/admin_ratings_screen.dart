import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rating_providers.dart';
import '../domain/user_rating.dart';

class AdminRatingsScreen extends ConsumerWidget {
  const AdminRatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsyncValue = ref.watch(adminRatingsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peer Ratings Overview'),
        centerTitle: true,
      ),
      body: summaryAsyncValue.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return const Center(child: Text('No rating data available.'));
          }

          // Sort by average rating descending
          final sortedSummaries = List<AdminRatingSummary>.from(summaries)
            ..sort((a, b) => b.averageRating.compareTo(a.averageRating));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedSummaries.length,
            itemBuilder: (context, index) {
              final summary = sortedSummaries[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForRating(summary.averageRating),
                    child: Text(
                      summary.averageRating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(summary.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${summary.departmentName} - ${summary.employeeId}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_alt, size: 16, color: Colors.grey),
                      Text('${summary.totalRatings} ratings', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Failed to load summary: $error',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
      ),
    );
  }

  Color _getColorForRating(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.orange;
    if (rating > 0) return Colors.red;
    return Colors.grey;
  }
}

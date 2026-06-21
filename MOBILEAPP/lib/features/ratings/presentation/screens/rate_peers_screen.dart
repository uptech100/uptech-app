import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rating_providers.dart';
import '../../domain/user_rating.dart';

class RatePeersScreen extends ConsumerWidget {
  const RatePeersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final usersAsyncValue = ref.watch(usersToRateProvider);
    final isSaturday = DateTime.now().weekday == DateTime.saturday;

    // For testing bypass, we can still show the UI even if it's not Saturday
    // But let's show a warning if it's not Saturday.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Peers'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (!isSaturday)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Note: Official ratings are meant for Saturdays. Submitting now uses developer bypass.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: usersAsyncValue.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(child: Text('No peers available to rate.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _RateUserCard(user: user);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Failed to load peers: $error',
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateUserCard extends ConsumerStatefulWidget {
  final RateableUser user;

  const _RateUserCard({required this.user});

  @override
  ConsumerState<_RateUserCard> createState() => _RateUserCardState();
}

class _RateUserCardState extends ConsumerState<_RateUserCard> {
  double _rating = 0;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  void _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating from 1 to 5 stars.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(ratingRepositoryProvider);
      await repository.submitRating(widget.user.id, _rating);
      
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating submitted for ${widget.user.name}!')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isSubmitted) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.check, color: Colors.white),
          ),
          title: Text(widget.user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Rating submitted successfully.'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    widget.user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${widget.user.departmentName} - ${widget.user.employeeId}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

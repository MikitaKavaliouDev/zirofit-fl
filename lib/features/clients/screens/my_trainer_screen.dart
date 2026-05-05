import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

/// Client-facing screen that shows the current trainer info and an option
/// to unlink from the trainer.
class MyTrainerScreen extends ConsumerStatefulWidget {
  /// Optional [ApiClient] override for dependency injection (testing).
  final ApiClient? apiClient;

  const MyTrainerScreen({super.key, this.apiClient});

  @override
  ConsumerState<MyTrainerScreen> createState() => _MyTrainerScreenState();
}

class _MyTrainerScreenState extends ConsumerState<MyTrainerScreen> {
  Map<String, dynamic>? _trainer;
  bool _isLoading = true;
  bool _isUnlinking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchTrainer);
  }

  Future<void> _fetchTrainer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = widget.apiClient ?? ApiClient.instance;
      final response = await client.get('/client/trainer');
      final data = response['data'];
      setState(() {
        _trainer = data is Map<String, dynamic> ? data : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = _extractErrorMessage(e);
      });
    }
  }

  Future<void> _unlinkTrainer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Trainer'),
        content: const Text(
          'Are you sure you want to unlink from your trainer? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUnlinking = true);

    try {
      final client = widget.apiClient ?? ApiClient.instance;
      await client.delete('/client/trainer');
      setState(() {
        _trainer = null;
        _isUnlinking = false;
      });

      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully unlinked from trainer.')),
      );
    } catch (e) {
      setState(() => _isUnlinking = false);

      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          // ignore: use_build_context_synchronously
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Trainer')),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchTrainer,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trainer == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off,
                  size: 64, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No trainer assigned yet.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your trainer will appear here once assigned.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final trainer = _trainer!;
    final name = trainer['name'] as String? ?? 'Unknown Trainer';
    final email = trainer['email'] as String?;
    final phone = trainer['phone'] as String?;
    final photoPath = trainer['avatar_path'] as String? ??
        trainer['profile_photo_path'] as String?;
    final specialties = trainer['specialties'] as List<dynamic>? ?? [];
    final aboutMe = trainer['about_me'] as String?;
    final rating = (trainer['average_rating'] as num?)?.toDouble();
    final location = trainer['location'] as String?;

    return RefreshIndicator(
      onRefresh: _fetchTrainer,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Trainer Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage:
                  photoPath != null ? NetworkImage(photoPath) : null,
              child: photoPath == null
                  ? Text(
                      _initials(name),
                      style: TextStyle(
                        fontSize: 32,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Name
            Text(name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),

            // Rating
            if (rating != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Contact Info
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (email != null)
                      _InfoRow(
                        icon: Icons.email,
                        label: email,
                      ),
                    if (email != null && phone != null)
                      const SizedBox(height: 12),
                    if (phone != null)
                      _InfoRow(
                        icon: Icons.phone,
                        label: phone,
                      ),
                    if ((email != null || phone != null) &&
                        location != null)
                      const SizedBox(height: 12),
                    if (location != null)
                      _InfoRow(
                        icon: Icons.location_on,
                        label: location,
                      ),
                  ],
                ),
              ),
            ),

            // About
            if (aboutMe != null && aboutMe.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('About',
                    style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(aboutMe,
                      style: theme.textTheme.bodyLarge),
                ),
              ),
            ],

            // Specialties
            if (specialties.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Specialties',
                    style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: specialties.map((s) {
                  return Chip(
                    label: Text(s.toString(),
                        style: theme.textTheme.bodySmall),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),

            // Unlink Button
            OutlinedButton.icon(
              onPressed: _isUnlinking ? null : _unlinkTrainer,
              icon: _isUnlinking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link_off),
              label: Text(
                  _isUnlinking ? 'Unlinking...' : 'Unlink from Trainer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

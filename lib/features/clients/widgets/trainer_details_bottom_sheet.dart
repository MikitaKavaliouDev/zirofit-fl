import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

class TrainerDetailsBottomSheet extends ConsumerStatefulWidget {
  final ApiClient? apiClient;

  const TrainerDetailsBottomSheet({super.key, this.apiClient});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TrainerDetailsBottomSheet(),
    );
  }

  @override
  ConsumerState<TrainerDetailsBottomSheet> createState() => _TrainerDetailsBottomSheetState();
}

class _TrainerDetailsBottomSheetState extends ConsumerState<TrainerDetailsBottomSheet> {
  Map<String, dynamic>? _trainerResponse;
  bool _isLoading = true;
  bool _isUnlinking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchTrainer);
  }

  Future<void> _fetchTrainer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = widget.apiClient ?? ApiClient.instance;
      final response = await client.get('/client/trainer');
      final data = response['data'];
      if (!mounted) return;
      setState(() {
        _trainerResponse = data is Map<String, dynamic> ? data : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _trainerResponse = null;
        _isUnlinking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully unlinked from trainer.')),
      );
      Navigator.of(context).pop(); // Close bottom sheet after unlinking
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUnlinking = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
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

    if (_trainerResponse == null || _trainerResponse!['trainer'] == null) {
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

    final trainerData = _trainerResponse!['trainer'] as Map<String, dynamic>;
    final profile = trainerData['profile'] as Map<String, dynamic>? ?? {};
    
    final name = trainerData['name'] as String? ?? 'Unknown Trainer';
    final email = trainerData['email'] as String?;
    final phone = trainerData['phone'] as String? ?? profile['phone'] as String?;
    final photoPath = profile['profilePhotoPath'] as String? ?? 
                      trainerData['avatar_path'] as String? ??
                      trainerData['profile_photo_path'] as String?;
    final specialties = (profile['specialties'] as List<dynamic>? ?? 
                        trainerData['specialties'] as List<dynamic>? ?? []);
    final aboutMe = profile['aboutMe'] as String? ?? 
                    trainerData['about_me'] as String?;
    final rating = (trainerData['average_rating'] as num? ?? 
                    profile['averageRating'] as num?)?.toDouble();
    final location = trainerData['location'] as String? ?? 
                     profile['location'] as String?;

    return RefreshIndicator(
      onRefresh: _fetchTrainer,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Trainer Avatar
            CircleAvatar(
              radius: 56,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: photoPath != null && photoPath.isNotEmpty
                  ? NetworkImage(photoPath)
                  : null,
              child: photoPath == null || photoPath.isEmpty
                  ? Text(
                      _initials(name),
                      style: TextStyle(
                        fontSize: 36,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 20),

            // Name
            Text(
              name, 
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Rating
            if (rating != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Contact Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (email != null)
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: email,
                    ),
                  if (email != null && phone != null)
                    const Divider(height: 24),
                  if (phone != null)
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: phone,
                    ),
                  if ((email != null || phone != null) &&
                      location != null)
                    const Divider(height: 24),
                  if (location != null)
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: location,
                    ),
                ],
              ),
            ),

            // About
            if (aboutMe != null && aboutMe.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('About',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  aboutMe.replaceAll(RegExp(r'<[^>]*>'), ''), // Simple HTML strip
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // Specialties
            if (specialties.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Specialties',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specialties.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Unlink Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/trainer_invitation_data.dart';
import 'package:zirofit_fl/features/clients/providers/trainer_invitation_provider.dart';

// ---------------------------------------------------------------------------
// Trainer Invitation Screen
// ---------------------------------------------------------------------------

/// Full-screen view for a client to review (accept/decline) a trainer's
/// invitation, matching the iOS [TrainerInvitationDetailView.swift] layout.
///
/// Receives the [token] from the deep link / notification and optionally a
/// [trainerName] hint to show while the profile is loading.
class TrainerInvitationScreen extends ConsumerStatefulWidget {
  final String token;
  final String? trainerName;

  const TrainerInvitationScreen({
    super.key,
    required this.token,
    this.trainerName,
  });

  @override
  ConsumerState<TrainerInvitationScreen> createState() =>
      _TrainerInvitationScreenState();
}

class _TrainerInvitationScreenState
    extends ConsumerState<TrainerInvitationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch trainer profile on mount
    Future.microtask(() {
      ref
          .read(trainerInvitationProvider.notifier)
          .fetchTrainerProfile(widget.token);
    });
  }

  Future<void> _handleAccept() async {
    final notifier = ref.read(trainerInvitationProvider.notifier);
    final success = await notifier.acceptInvitation(widget.token);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation accepted! You are now connected.'),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to client dashboard
      context.go('/client/dashboard');
    } else {
      final state = ref.read(trainerInvitationProvider);
      if (state.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDecline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: const Text(
          'Are you sure you want to decline this invitation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final notifier = ref.read(trainerInvitationProvider.notifier);
    final success = await notifier.declineInvitation(widget.token);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation declined.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trainerInvitationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: _buildBody(state, theme),
      ),
    );
  }

  Widget _buildBody(TrainerInvitationState state, ThemeData theme) {
    switch (state.status) {
      case TrainerInvitationStatus.initial:
      case TrainerInvitationStatus.loading:
        return _buildLoading(theme);

      case TrainerInvitationStatus.loaded:
        if (state.trainer == null) {
          return _buildError(
            theme,
            'Unable to load trainer profile.',
          );
        }
        return _buildProfileContent(state.trainer!, theme);

      case TrainerInvitationStatus.accepting:
        // Show the profile but with a loading overlay on accept button
        if (state.trainer != null) {
          return _buildProfileContent(state.trainer!, theme,
              isAccepting: true);
        }
        return _buildLoading(theme);

      case TrainerInvitationStatus.declining:
        if (state.trainer != null) {
          return _buildProfileContent(state.trainer!, theme,
              isDeclining: true);
        }
        return _buildLoading(theme);

      case TrainerInvitationStatus.accepted:
        // Should not render; navigation happens in _handleAccept
        return const SizedBox.shrink();

      case TrainerInvitationStatus.declined:
        // Should not render; navigation happens in _handleDecline
        return const SizedBox.shrink();

      case TrainerInvitationStatus.error:
        return _buildError(theme, state.error ?? 'Something went wrong.');
    }
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            widget.trainerName != null
                ? 'Loading ${widget.trainerName}\'s profile...'
                : 'Fetching trainer profile...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load trainer profile',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref
                    .read(trainerInvitationProvider.notifier)
                    .fetchTrainerProfile(widget.token);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    TrainerInvitationData trainer,
    ThemeData theme, {
    bool isAccepting = false,
    bool isDeclining = false,
  }) {
    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // -----------------------------------------------------------------
                // Banner header (200px) — matches iOS layout
                // -----------------------------------------------------------------
                _InvitationBanner(
                  bannerUrl: trainer.bannerUrl,
                  avatarUrl: trainer.avatarUrl,
                  trainerName: trainer.name,
                ),

                // -----------------------------------------------------------------
                // Trainer name + location
                // -----------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        trainer.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (trainer.location != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trainer.location!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // -----------------------------------------------------------------
                // Specialties as blue pill chips
                // -----------------------------------------------------------------
                if (trainer.specialties.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: trainer.specialties.map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            specialty,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // -----------------------------------------------------------------
                // About section
                // -----------------------------------------------------------------
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trainer.bio ?? 'No bio available.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // -----------------------------------------------------------------
        // Action buttons — pinned at bottom
        // -----------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Accept button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed:
                      (isAccepting || isDeclining) ? null : _handleAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isAccepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Accept Invitation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Decline button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed:
                      (isAccepting || isDeclining) ? null : _handleDecline,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isDeclining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red,
                          ),
                        )
                      : const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Invitation Banner — 200px banner with gradient fallback + avatar
// ===========================================================================

class _InvitationBanner extends StatelessWidget {
  final String? bannerUrl;
  final String? avatarUrl;
  final String trainerName;

  const _InvitationBanner({
    this.bannerUrl,
    this.avatarUrl,
    required this.trainerName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner image or gradient fallback
          if (bannerUrl != null && bannerUrl!.isNotEmpty)
            Image.network(
              bannerUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackBanner(),
            )
          else
            _buildFallbackBanner(),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // Avatar — offset 60px below the banner bottom
          Positioned(
            bottom: -60,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.surface,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

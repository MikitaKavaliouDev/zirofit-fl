import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/settings/providers/storefront_provider.dart';

// ---------------------------------------------------------------------------
// Storefront Settings Screen
// ---------------------------------------------------------------------------

/// Manages storefront visibility, featured status, and links to the profile/
/// services/packages management screens.
class StorefrontSettingsScreen extends ConsumerStatefulWidget {
  const StorefrontSettingsScreen({super.key});

  @override
  ConsumerState<StorefrontSettingsScreen> createState() =>
      _StorefrontSettingsScreenState();
}

class _StorefrontSettingsScreenState
    extends ConsumerState<StorefrontSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storefrontProvider.notifier).fetchStorefront();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storefrontProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Storefront Settings')),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(StorefrontState state, ThemeData theme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(storefrontProvider.notifier).fetchStorefront(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success/Error feedback
            if (state.successMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MessageBanner(
                  message: state.successMessage!,
                  type: _BannerType.success,
                  onDismiss: () {
                    ref
                        .read(storefrontProvider.notifier)
                        .fetchStorefront();
                  },
                ),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MessageBanner(
                  message: state.error!,
                  type: _BannerType.error,
                  onDismiss: () {
                    ref
                        .read(storefrontProvider.notifier)
                        .fetchStorefront();
                  },
                ),
              ),

            // -- Visibility Section --
            const _SectionHeader(
              icon: Icons.visibility,
              title: 'Storefront Visibility',
            ),
            const SizedBox(height: 12),
            _VisibilityCard(
              isVisible: state.isVisible,
              isSaving: state.isSaving,
              onToggle: () {
                ref
                    .read(storefrontProvider.notifier)
                    .toggleVisibility();
              },
            ),
            const SizedBox(height: 24),

            // -- Featured Status --
            const _SectionHeader(
              icon: Icons.star,
              title: 'Featured Status',
            ),
            const SizedBox(height: 12),
            _FeaturedCard(
              isFeatured: state.isFeatured,
              isSaving: state.isSaving,
              onToggle: () {
                ref
                    .read(storefrontProvider.notifier)
                    .toggleFeatured();
              },
            ),
            const SizedBox(height: 24),

            // -- Quick Links --
            const _SectionHeader(
              icon: Icons.launch,
              title: 'Manage Content',
            ),
            const SizedBox(height: 12),
            _QuickLinkCard(
              icon: Icons.work_outline,
              title: 'Services',
              subtitle: 'Manage your service offerings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Services management'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _QuickLinkCard(
              icon: Icons.inventory_2_outlined,
              title: 'Packages',
              subtitle: 'Manage session packages and pricing',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Packages management'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _QuickLinkCard(
              icon: Icons.format_quote,
              title: 'Testimonials',
              subtitle: 'Manage client testimonials',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Navigate to Testimonials management'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _QuickLinkCard(
              icon: Icons.photo_library_outlined,
              title: 'Transformation Photos',
              subtitle: 'Manage client transformation photos',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Navigate to Transformation Photos'),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // -- Platform Info --
            const _SectionHeader(
              icon: Icons.info_outline,
              title: 'Platform & Fees',
            ),
            const SizedBox(height: 12),
            _PlatformFeeCard(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Banner
// ---------------------------------------------------------------------------

enum _BannerType { success, error }

class _MessageBanner extends StatelessWidget {
  final String message;
  final _BannerType type;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = type == _BannerType.success
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final fgColor = type == _BannerType.success
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;
    final icon = type == _BannerType.success
        ? Icons.check_circle
        : Icons.error;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: fgColor),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: fgColor),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Visibility Card
// ---------------------------------------------------------------------------

class _VisibilityCard extends StatelessWidget {
  final bool isVisible;
  final bool isSaving;
  final VoidCallback onToggle;

  const _VisibilityCard({
    required this.isVisible,
    required this.isSaving,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: isVisible ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVisible
                            ? 'Your storefront is visible'
                            : 'Your storefront is hidden',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        isVisible
                            ? 'Trainers can find you in the marketplace'
                            : 'Your profile is hidden from search results',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isVisible,
                  onChanged: isSaving ? null : (_) => onToggle(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Featured Card
// ---------------------------------------------------------------------------

class _FeaturedCard extends StatelessWidget {
  final bool isFeatured;
  final bool isSaving;
  final VoidCallback onToggle;

  const _FeaturedCard({
    required this.isFeatured,
    required this.isSaving,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFeatured ? Icons.star : Icons.star_border,
                  color: isFeatured ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFeatured
                            ? 'Featured Trainer'
                            : 'Not Featured',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        isFeatured
                            ? 'Your profile is highlighted in the marketplace'
                            : 'Apply to become a featured trainer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isFeatured,
                  onChanged: isSaving ? null : (_) => onToggle(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Link Card
// ---------------------------------------------------------------------------

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform Fee Card
// ---------------------------------------------------------------------------

class _PlatformFeeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Ziro Platform Fee',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '5%',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This fee helps us maintain the platform and process your payments securely.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

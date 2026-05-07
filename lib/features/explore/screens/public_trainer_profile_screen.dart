import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/transformation_photo.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/data/models/public_trainer_profile_data.dart';
import 'package:zirofit_fl/features/explore/providers/explore_provider.dart';

// ---------------------------------------------------------------------------
// Public Trainer Profile Screen
// ---------------------------------------------------------------------------

class PublicTrainerProfileScreen extends ConsumerStatefulWidget {
  final Profile trainer;

  const PublicTrainerProfileScreen({super.key, required this.trainer});

  @override
  ConsumerState<PublicTrainerProfileScreen> createState() =>
      _PublicTrainerProfileScreenState();
}

class _PublicTrainerProfileScreenState
    extends ConsumerState<PublicTrainerProfileScreen> {
  PublicTrainerProfileData? _profileData;
  bool _isLoading = true;
  String? _error;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadFullProfile();
  }

  Future<void> _loadFullProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Use trainer display name (aboutMe) as the username for lookup
    final username = widget.trainer.aboutMe ?? widget.trainer.userId;
    final notifier = ref.read(exploreProvider.notifier);
    final data = await notifier.fetchFullPublicProfile(username);

    if (!mounted) return;

    if (data != null) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } else {
      // If fetch fails, show the basic profile info without extra marketplace data
      setState(() {
        _isLoading = false;
        _error = 'Could not load full profile. Showing basic info.';
      });
    }
  }

  Future<void> _handleConnect() async {
    setState(() => _isConnecting = true);
    final notifier = ref.read(exploreProvider.notifier);
    final success =
        await notifier.requestConnectTrainer(widget.trainer.userId);
    if (!mounted) return;
    setState(() => _isConnecting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Connection request sent to ${widget.trainer.aboutMe ?? "trainer"}!'
              : 'Failed to send connection request. Please try again.',
        ),
        backgroundColor: success
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _handleBookSession() {
    context.push('/client/bookings/${widget.trainer.userId}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null) {
      return _buildError();
    }

    // Use fetched data if available, otherwise fall back to basic profile
    final profile = _profileData?.profile ?? widget.trainer;
    final packages = _profileData?.packages ?? [];
    final services = _profileData?.services ?? [];
    final transformations = _profileData?.transformations ?? [];
    final testimonials = _profileData?.testimonials ?? [];
    final socialLinks = _profileData?.socialLinks ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.aboutMe ?? 'Trainer Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFullProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(profile),
            const SizedBox(height: 24),

            // About / Bio
            _buildSection(
              context,
              title: 'About',
              content: profile.aboutMe,
            ),

            // Philosophy
            _buildSection(
              context,
              title: 'Philosophy',
              content: profile.philosophy,
            ),

            // Methodology
            _buildSection(
              context,
              title: 'Methodology',
              content: profile.methodology,
            ),

            // Specialties
            if (profile.specialties.isNotEmpty) ...[
              _buildSectionTitle(context, 'Specialties'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: profile.specialties.map((specialty) {
                  return Chip(
                    label: Text(specialty),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Certifications
            _buildSection(
              context,
              title: 'Certifications',
              content: profile.certifications,
            ),

            // Services
            if (services.isNotEmpty) ...[
              _buildSectionTitle(context, 'Services'),
              const SizedBox(height: 8),
              ...services.map((s) => _ServiceCard(service: s)),
              const SizedBox(height: 24),
            ],

            // Packages with purchase CTA
            if (packages.isNotEmpty) ...[
              _buildSectionTitle(context, 'Packages'),
              const SizedBox(height: 8),
              ...packages.map((p) => _PackageCard(
                    package: p,
                    currency: profile.businessCurrency,
                  )),
              const SizedBox(height: 24),
            ],

            // Transformation Photos Gallery
            if (transformations.isNotEmpty) ...[
              _buildSectionTitle(context, 'Transformation Photos'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: transformations.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _TransformationCard(photo: transformations[i]),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Testimonials / Reviews
            if (testimonials.isNotEmpty) ...[
              _buildSectionTitle(context, 'Testimonials'),
              const SizedBox(height: 8),
              ...testimonials
                  .map((t) => _TestimonialCard(testimonial: t)),
              const SizedBox(height: 24),
            ],

            // Social Links
            if (socialLinks.isNotEmpty) ...[
              _buildSectionTitle(context, 'Social Links'),
              const SizedBox(height: 8),
              ...socialLinks.map((l) => _SocialLinkTile(link: l)),
              const SizedBox(height: 24),
            ],

            // Price info
            if (profile.minServicePrice != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'From ${profile.minServicePrice!.toStringAsFixed(2)} ${profile.businessCurrency}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            _buildActionButtons(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading / Error
  // ---------------------------------------------------------------------------

  Widget _buildLoading() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trainer.aboutMe ?? 'Trainer Profile'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trainer.aboutMe ?? 'Trainer Profile'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Unable to load full profile',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadFullProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeaderSection(Profile trainer) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: trainer.profilePhotoPath != null
                ? NetworkImage(trainer.profilePhotoPath!)
                : null,
            child: trainer.profilePhotoPath == null
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            trainer.aboutMe ?? 'Trainer',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (trainer.location != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  trainer.location!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          if (trainer.averageRating != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 20, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  trainer.averageRating!.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section helpers
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? content,
  }) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, title),
        const SizedBox(height: 8),
        Text(content, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Action buttons
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Book Session button
        FilledButton.icon(
          onPressed: _handleBookSession,
          icon: const Icon(Icons.calendar_today),
          label: const Text('Book Session'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
        const SizedBox(height: 12),
        // Connect button
        OutlinedButton.icon(
          onPressed: _isConnecting ? null : _handleConnect,
          icon: _isConnecting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add),
          label: Text(
              _isConnecting ? 'Sending...' : 'Connect with Trainer'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Service Card
// ---------------------------------------------------------------------------

class _ServiceCard extends StatelessWidget {
  final Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (service.price != null)
                  Text(
                    '${service.price!.toStringAsFixed(2)} ${service.currency ?? 'USD'}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                service.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (service.duration != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${service.duration} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Package Card with Purchase CTA
// ---------------------------------------------------------------------------

class _PackageCard extends StatelessWidget {
  final Package package;
  final String currency;

  const _PackageCard({
    required this.package,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${package.price.toStringAsFixed(2)} $currency',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (package.description != null &&
                package.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                package.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.receipt_long,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${package.numberOfSessions} sessions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Purchase flow for ${package.name} — coming soon'),
                      ),
                    );
                  },
                  child: const Text('Purchase'),
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
// Transformation Photo Card
// ---------------------------------------------------------------------------

class _TransformationCard extends StatelessWidget {
  final TransformationPhoto photo;

  const _TransformationCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: photo.imagePath.isNotEmpty
                  ? Image.network(
                      photo.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
            if (photo.caption != null ||
                photo.clientName != null) ...[
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photo.clientName != null)
                      Text(
                        photo.clientName!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    if (photo.caption != null)
                      Text(
                        photo.caption!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Testimonial Card
// ---------------------------------------------------------------------------

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;

  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    testimonial.clientName.isNotEmpty
                        ? testimonial.clientName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    testimonial.clientName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (testimonial.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${testimonial.rating}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              testimonial.testimonialText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Social Link Tile
// ---------------------------------------------------------------------------

class _SocialLinkTile extends StatelessWidget {
  final SocialLink link;

  const _SocialLinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    switch (link.platform.toLowerCase()) {
      case 'instagram':
        icon = Icons.camera_alt;
        break;
      case 'youtube':
        icon = Icons.play_circle;
        break;
      case 'twitter':
      case 'x':
        icon = Icons.alternate_email;
        break;
      case 'linkedin':
        icon = Icons.work;
        break;
      case 'facebook':
        icon = Icons.facebook;
        break;
      case 'tiktok':
        icon = Icons.music_note;
        break;
      default:
        icon = Icons.link;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        '${link.platform} — @${link.username}',
        style: theme.textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () {
        // In a real app, this would launch the URL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open ${link.profileUrl}')),
        );
      },
    );
  }
}

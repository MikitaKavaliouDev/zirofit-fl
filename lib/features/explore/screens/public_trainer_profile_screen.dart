import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
    extends ConsumerState<PublicTrainerProfileScreen>
    with SingleTickerProviderStateMixin {
  PublicTrainerProfileData? _profileData;
  bool _isLoading = true;
  String? _error;
  bool _isConnecting = false;
  String _connectStatus = 'none'; // 'none' | 'pending' | 'connected'
  String? _purchasingPackageId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFullProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFullProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final username = widget.trainer.aboutMe ?? widget.trainer.userId;
    final notifier = ref.read(exploreProvider.notifier);
    final data = await notifier.fetchFullPublicProfile(username);

    if (!mounted) return;

    if (data != null) {
      setState(() {
        _profileData = data;
        _isLoading = false;
        _connectStatus =
            data.connectStatus ?? 'none';
      });
    } else {
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
    setState(() {
      _isConnecting = false;
      if (success) {
        _connectStatus = 'pending';
      }
    });

    if (mounted) {
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
  }

  void _handleBookSession() {
    context.push('/client/bookings/${widget.trainer.userId}');
  }

  Future<void> _handlePurchase(Package package) async {
    setState(() => _purchasingPackageId = package.id);

    final notifier = ref.read(exploreProvider.notifier);
    final url = await notifier.createCheckoutSession(package.id);

    if (!mounted) return;
    setState(() => _purchasingPackageId = null);

    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open checkout page: $url')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start checkout. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_error != null && _profileData == null) {
      return _buildError();
    }

    final profile = _profileData?.profile ?? widget.trainer;
    final packages = _profileData?.packages ?? [];
    final services = _profileData?.services ?? [];
    final transformations = _profileData?.transformations ?? [];
    final testimonials = _profileData?.testimonials ?? [];
    final socialLinks = _profileData?.socialLinks ?? [];

    return Scaffold(
      body: Column(
        children: [
          // -----------------------------------------------------------------
          // Banner (180px)
          // -----------------------------------------------------------------
          _BannerHeader(
            bannerUrl: profile.bannerImagePath,
            avatarUrl: profile.profilePhotoPath,
          ),

          // -----------------------------------------------------------------
          // Content area (scrollable below the banner)
          // -----------------------------------------------------------------
          Expanded(
            child: Column(
              children: [
                // Avatar overlap + Trainer name / location
                _ProfileIdentity(
                  trainer: profile,
                ),

                // Stats row
                _StatsRow(
                  reviewsCount: testimonials.length,
                  programsCount: packages.length,
                  rating: profile.averageRating,
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          onPressed: _handleBookSession,
                          label: 'Book Session',
                          icon: Icons.calendar_today,
                          isFilled: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ConnectButton(
                          connectStatus: _connectStatus,
                          isConnecting: _isConnecting,
                          onConnect: _handleConnect,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab bar
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Packages'),
                      Tab(text: 'Photos'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AboutTab(
                        profile: profile,
                        services: services,
                        socialLinks: socialLinks,
                      ),
                      _PackagesTab(
                        packages: packages,
                        currency: profile.businessCurrency,
                        purchasingId: _purchasingPackageId,
                        onPurchase: _handlePurchase,
                      ),
                      _PhotosTab(transformations: transformations),
                      _ReviewsTab(testimonials: testimonials),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

// ===========================================================================
// Banner Header (180px) with gradient overlay
// ===========================================================================

class _BannerHeader extends StatelessWidget {
  final String? bannerUrl;
  final String? avatarUrl;

  const _BannerHeader({this.bannerUrl, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Banner image
          if (bannerUrl != null && bannerUrl!.isNotEmpty)
            Image.network(
              bannerUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallbackBanner(context),
            )
          else
            _buildFallbackBanner(context),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // Avatar - positioned to overlap bottom by 50px
          Positioned(
            bottom: -50,
            left: 24,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.surface,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(Icons.person,
                      size: 50,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.7),
            theme.colorScheme.secondary.withValues(alpha: 0.4),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Profile Identity (name, location, below avatar)
// ===========================================================================

class _ProfileIdentity extends StatelessWidget {
  final Profile trainer;

  const _ProfileIdentity({required this.trainer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trainer.aboutMe ?? 'Trainer',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trainer.location != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
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
    );
  }
}

// ===========================================================================
// Stats Row
// ===========================================================================

class _StatsRow extends StatelessWidget {
  final int reviewsCount;
  final int programsCount;
  final double? rating;

  const _StatsRow({
    required this.reviewsCount,
    required this.programsCount,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Reviews count
          _StatItem(
            icon: Icons.reviews_outlined,
            value: '$reviewsCount',
            label: 'Reviews',
          ),
          const SizedBox(width: 32),
          // Programs count
          _StatItem(
            icon: Icons.fitness_center_outlined,
            value: '$programsCount',
            label: 'Programs',
          ),
          const SizedBox(width: 32),
          // Rating
          if (rating != null)
            Row(
              children: [
                ...List.generate(5, (i) {
                  final starValue = i + 1;
                  if (rating! >= starValue) {
                    return const Icon(Icons.star,
                        size: 18, color: Color(0xFFF59E0B));
                  } else if (rating! >= starValue - 0.5) {
                    return const Icon(Icons.star_half,
                        size: 18, color: Color(0xFFF59E0B));
                  } else {
                    return Icon(Icons.star_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant);
                  }
                }),
                const SizedBox(width: 4),
                Text(
                  rating!.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Action Buttons
// ===========================================================================

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final bool isFilled;
  final bool isLoading;

  const _ActionButton({
    this.onPressed,
    required this.label,
    required this.icon,
    this.isFilled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = isFilled ? FilledButton.icon : OutlinedButton.icon;

    return SizedBox(
      height: 48,
      child: button(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final String connectStatus;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _ConnectButton({
    required this.connectStatus,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    String text;
    Color? backgroundColor;

    switch (connectStatus) {
      case 'connected':
        icon = Icons.check_circle;
        text = 'Connected';
        backgroundColor = theme.colorScheme.primaryContainer;
      case 'pending':
        icon = Icons.hourglass_empty;
        text = 'Request Sent';
        backgroundColor = theme.colorScheme.secondaryContainer;
      default:
        icon = Icons.person_add;
        text = 'Connect';
        backgroundColor = null;
    }

    if (connectStatus == 'connected' || connectStatus == 'pending') {
      return SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: Icon(icon, size: 18),
          label: Text(text, style: const TextStyle(fontSize: 14)),
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor?.withValues(alpha: 0.3),
            side: BorderSide(
              color: backgroundColor?.withValues(alpha: 0.5) ??
                  theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: FilledButton.tonalIcon(
        onPressed: isConnecting ? null : onConnect,
        icon: isConnecting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add, size: 18),
        label: Text(
          isConnecting ? 'Sending...' : text,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

// ===========================================================================
// About Tab
// ===========================================================================

class _AboutTab extends StatefulWidget {
  final Profile profile;
  final List<Service> services;
  final List<SocialLink> socialLinks;

  const _AboutTab({
    required this.profile,
    required this.services,
    required this.socialLinks,
  });

  @override
  State<_AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<_AboutTab> {
  bool _bioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bio (collapsible)
        if (widget.profile.aboutMe != null &&
            widget.profile.aboutMe!.isNotEmpty) ...[
          _SectionTitle(title: 'About'),
          const SizedBox(height: 8),
          _CollapsibleText(
            text: widget.profile.aboutMe!,
            expanded: _bioExpanded,
            onToggle: () => setState(() => _bioExpanded = !_bioExpanded),
          ),
          const SizedBox(height: 24),
        ],

        // Philosophy
        if (widget.profile.philosophy != null &&
            widget.profile.philosophy!.isNotEmpty) ...[
          _SectionTitle(title: 'Philosophy'),
          const SizedBox(height: 8),
          Text(
            widget.profile.philosophy!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Methodology
        if (widget.profile.methodology != null &&
            widget.profile.methodology!.isNotEmpty) ...[
          _SectionTitle(title: 'Methodology'),
          const SizedBox(height: 8),
          Text(
            widget.profile.methodology!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Specialties
        if (widget.profile.specialties.isNotEmpty) ...[
          _SectionTitle(title: 'Specialties'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.profile.specialties.map((specialty) {
              return Chip(
                label: Text(specialty),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
                backgroundColor:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Certifications
        if (widget.profile.certifications != null &&
            widget.profile.certifications!.isNotEmpty) ...[
          _SectionTitle(title: 'Certifications'),
          const SizedBox(height: 8),
          Text(
            widget.profile.certifications!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Services (first 3)
        if (widget.services.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle(title: 'Services'),
              if (widget.services.length > 3)
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All services view')),
                    );
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.services
              .take(3)
              .map((s) => _ServiceCard(service: s)),
          if (widget.services.isNotEmpty) const SizedBox(height: 24),
        ],

        // External / Social Links
        if (widget.socialLinks.isNotEmpty) ...[
          _SectionTitle(title: 'Connect Online'),
          const SizedBox(height: 8),
          ...widget.socialLinks.map((l) => _SocialLinkTile(link: l)),
          const SizedBox(height: 24),
        ],

        // Price info
        if (widget.profile.minServicePrice != null) ...[
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.attach_money,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'From ${widget.profile.minServicePrice!.toStringAsFixed(2)} ${widget.profile.businessCurrency}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _CollapsibleText extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleText({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: expanded ? null : 3,
          overflow: expanded ? null : TextOverflow.ellipsis,
        ),
        if (text.length > 150) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onToggle,
            child: Text(
              expanded ? 'Show less' : 'Read more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ===========================================================================
// Packages Tab
// ===========================================================================

class _PackagesTab extends StatelessWidget {
  final List<Package> packages;
  final String currency;
  final String? purchasingId;
  final void Function(Package) onPurchase;

  const _PackagesTab({
    required this.packages,
    required this.currency,
    this.purchasingId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No packages available yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final isPurchasing = purchasingId == pkg.id;

        return _PackageCard(
          package: pkg,
          currency: currency,
          isPurchasing: isPurchasing,
          onPurchase: () => onPurchase(pkg),
        );
      },
    );
  }
}

// ===========================================================================
// Photos Tab
// ===========================================================================

class _PhotosTab extends StatelessWidget {
  final List<TransformationPhoto> transformations;

  const _PhotosTab({required this.transformations});

  @override
  Widget build(BuildContext context) {
    if (transformations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No transformation photos yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: transformations.length,
      itemBuilder: (context, index) {
        return _TransformationGridCard(photo: transformations[index]);
      },
    );
  }
}

// ===========================================================================
// Reviews Tab
// ===========================================================================

class _ReviewsTab extends StatelessWidget {
  final List<Testimonial> testimonials;

  const _ReviewsTab({required this.testimonials});

  @override
  Widget build(BuildContext context) {
    if (testimonials.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: testimonials.length,
      itemBuilder: (context, index) {
        return _TestimonialCard(testimonial: testimonials[index]);
      },
    );
  }
}

// ===========================================================================
// Section Title
// ===========================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ===========================================================================
// Service Card
// ===========================================================================

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

// ===========================================================================
// Package Card with real Stripe Purchase
// ===========================================================================

class _PackageCard extends StatelessWidget {
  final Package package;
  final String currency;
  final bool isPurchasing;
  final VoidCallback onPurchase;

  const _PackageCard({
    required this.package,
    required this.currency,
    this.isPurchasing = false,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${package.price.toStringAsFixed(2)} $currency',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (package.description != null &&
                package.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                package.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.receipt_long,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${package.numberOfSessions} sessions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: isPurchasing ? null : onPurchase,
                  child: isPurchasing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Purchase'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Transformation Photo Card (Grid)
// ===========================================================================

class _TransformationGridCard extends StatelessWidget {
  final TransformationPhoto photo;

  const _TransformationGridCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (photo.caption != null)
                    Text(
                      photo.caption!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
    );
  }
}

// ===========================================================================
// Testimonial Card
// ===========================================================================

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;

  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dateStr = _formatDate(testimonial.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    testimonial.clientName.isNotEmpty
                        ? testimonial.clientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testimonial.clientName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (testimonial.rating != null)
                  Row(
                    children: [
                      ...List.generate(
                        testimonial.rating!,
                        (_) => const Icon(Icons.star,
                            size: 14, color: Color(0xFFF59E0B)),
                      ),
                      if (testimonial.rating! < 5)
                        ...List.generate(
                          5 - testimonial.rating!,
                          (_) => Icon(Icons.star_outline,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              testimonial.testimonialText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ===========================================================================
// Social Link Tile
// ===========================================================================

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
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(icon, size: 16, color: theme.colorScheme.primary),
      ),
      title: Text(
        '${link.platform} — @${link.username}',
        style: theme.textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open ${link.profileUrl}')),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zirofit_fl/features/settings/screens/contact_support_screen.dart';
import 'package:zirofit_fl/features/settings/screens/language_settings_screen.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVersion());
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = 'v${info.version}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _appVersion = 'v1.0.6');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isClient = location.startsWith('/client');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader(title: 'YOUR ACCOUNT'),
          const SizedBox(height: 8),
          if (isClient) ...[
            _MoreListTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => context.go('/client/settings'),
            ),
            _MoreListTile(
              icon: Icons.checklist_outlined,
              title: 'Check-in History',
              onTap: () => context.go('/client/check-in/history'),
            ),
            _MoreListTile(
              icon: Icons.receipt_long_outlined,
              title: 'Purchase History',
              onTap: () => context.go('/client/transactions'),
            ),
            _MoreListTile(
              icon: Icons.fitness_center_outlined,
              title: 'Programs',
              onTap: () => context.go('/client/programs'),
            ),
            _MoreListTile(
              icon: Icons.person_outline,
              title: 'My Trainer',
              onTap: () => context.go('/client/trainer'),
            ),
          ] else ...[
            _MoreListTile(
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () => context.go('/trainer/profile'),
            ),
            _MoreListTile(
              icon: Icons.qr_code_2_outlined,
              title: 'Digital Business Card',
              onTap: () => context.go('/trainer/qr-code'),
            ),
            _MoreListTile(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => context.go('/trainer/settings'),
            ),
            _MoreListTile(
              icon: Icons.checklist_outlined,
              title: 'Check-Ins',
              onTap: () => context.go('/trainer/check-ins'),
            ),
            _MoreListTile(
              icon: Icons.attach_money_outlined,
              title: 'Revenue',
              onTap: () => context.go('/trainer/revenue'),
            ),
            _MoreListTile(
              icon: Icons.receipt_long_outlined,
              title: 'Transaction History',
              onTap: () => context.go('/trainer/transactions'),
            ),
            _MoreListTile(
              icon: Icons.folder_outlined,
              title: 'Resources',
              onTap: () => context.go('/trainer/resources'),
            ),
            _MoreListTile(
              icon: Icons.restaurant_outlined,
              title: 'Recipes',
              onTap: () => context.go('/trainer/recipes'),
            ),
          ],
          _MoreListTile(
            icon: Icons.article_outlined,
            title: 'Blog',
            onTap: () => context.go('/blog'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          const _SectionHeader(title: 'SUPPORT & PREFERENCES'),
          const SizedBox(height: 8),
          _MoreListTile(
            icon: Icons.language_rounded,
            title: 'Language',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LanguageSettingsScreen(),
              ),
            ),
          ),
          _MoreListTile(
            icon: Icons.support_agent_outlined,
            title: 'Contact Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ContactSupportScreen(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          const _SectionHeader(title: 'ABOUT'),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Ziro Fit $_appVersion',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _MoreListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MoreListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

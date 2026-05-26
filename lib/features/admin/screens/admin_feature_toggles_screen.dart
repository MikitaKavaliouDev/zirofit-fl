import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';

class AdminFeatureTogglesScreen extends ConsumerStatefulWidget {
  const AdminFeatureTogglesScreen({super.key});

  @override
  ConsumerState<AdminFeatureTogglesScreen> createState() =>
      _AdminFeatureTogglesScreenState();
}

class _AdminFeatureTogglesScreenState
    extends ConsumerState<AdminFeatureTogglesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).fetchFeatureToggles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);
    final toggles = state.featureToggles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Toggles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(adminProvider.notifier).fetchFeatureToggles(),
          ),
        ],
      ),
      body: _buildBody(theme, state, toggles),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    AdminState state,
    Map<String, dynamic>? toggles,
  ) {
    if (state.isLoading && toggles == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (toggles == null || toggles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.toggle_off_outlined,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No feature toggles', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Feature toggles are not available.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminProvider.notifier).fetchFeatureToggles(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                _ToggleTile(
                  icon: Icons.lock_open,
                  title: 'Free Access Mode',
                  subtitle: 'Allow users to access the app without login',
                  value: toggles['freeAccessMode'] == true,
                  onChanged: (val) => _updateToggle(
                    'freeAccessMode',
                    val.toString(),
                  ),
                  theme: theme,
                ),
                const Divider(height: 1),
                _ToggleTile(
                  icon: Icons.language,
                  title: 'Custom Domains',
                  subtitle: 'Enable custom domain support for trainers',
                  value: toggles['customDomains'] == true,
                  onChanged: (val) => _updateToggle(
                    'customDomains',
                    val.toString(),
                  ),
                  theme: theme,
                ),
              ],
            ),
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                state.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _updateToggle(String key, String value) async {
    await ref.read(adminProvider.notifier).updateFeatureToggle(key, value);
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeData theme;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

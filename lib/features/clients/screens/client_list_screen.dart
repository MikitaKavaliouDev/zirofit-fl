import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/services/app_event_bus.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';
import 'package:zirofit_fl/features/clients/widgets/client_list_skeleton.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Cache-first: load from cache instantly, then fetch from API
      ref.read(clientListProvider.notifier).loadClients();
    });
  }

  /// Re-fetch client list when app context changes (mode switch).
  /// Mirrors iOS `appUserContextDidChange` notification handler.
  void _onAppUserContextWillChange() {
    ref.read(clientListProvider.notifier).fetchClients();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for mode switch events to re-fetch
    AppEventBus().onAppUserContextWillChange.addListener(_onAppUserContextWillChange);
  }

  @override
  void dispose() {
    AppEventBus().onAppUserContextWillChange.removeListener(_onAppUserContextWillChange);
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        ref.read(clientListProvider.notifier).setSearch('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientListProvider);
    final theme = Theme.of(context);

    // Show subtle loading bar when data is from cache but network fetch
    // is still in progress (cache-first loading)
    final showRefreshIndicator = state.isLoading && state.clients.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearchVisible ? 'Close search' : 'Search clients',
          ),
        ],
      ),
      body: Column(
        children: [
          // -- Animated search bar --
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isSearchVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(clientListProvider.notifier)
                                      .setSearch('');
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        ref
                            .read(clientListProvider.notifier)
                            .setSearch(value);
                        setState(() {}); // rebuild for suffix icon
                      },
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),

          // -- Background loading bar (cache-first) --
          if (showRefreshIndicator)
            const LinearProgressIndicator(minHeight: 2),

          // -- Content --
          Expanded(
            child: _buildContent(state, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/trainer/clients/invite'),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildContent(ClientListState state, ThemeData theme) {
    // Show skeleton during initial load (no cache data available)
    if (state.isLoading && state.clients.isEmpty && !state.isFromCache) {
      return const ClientListSkeleton();
    }

    // Error state
    if (state.hasError) {
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
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(clientListProvider.notifier).fetchClients(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final clients = state.filteredClients;

    // Empty state
    if (clients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: 64, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                state.searchQuery.isNotEmpty
                    ? 'No clients match "${state.searchQuery}"'
                    : 'No clients yet.\nInvite your first client!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -- Sectioned list --
    final pendingClients =
        clients.where((c) => c.status == 'pending').toList();
    final activeClients =
        clients.where((c) => c.status != 'pending').toList();

    final items = <_ListItem>[];
    if (pendingClients.isNotEmpty) {
      items.add(_ListItem.sectionHeader('Pending Invitations', Colors.orange));
      items.addAll(pendingClients.map(_ListItem.client));
      if (activeClients.isNotEmpty) {
        items.add(_ListItem.divider());
      }
    }
    if (activeClients.isNotEmpty) {
      items.add(_ListItem.sectionHeader('Active Clients', Colors.grey));
      items.addAll(activeClients.map(_ListItem.client));
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientListProvider.notifier).fetchClients(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return switch (item) {
            _ListItem(
              :final type,
              :final title,
              :final color,
              :final client,
            ) =>
              _buildItem(type, title, color, client, theme),
          };
        },
      ),
    );
  }

  Widget _buildItem(_ListItemType type, String? title, Color? color,
      Client? client, ThemeData theme) {
    switch (type) {
      case _ListItemType.sectionHeader:
        return _SectionHeader(title: title!, color: color!);
      case _ListItemType.divider:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1),
        );
      case _ListItemType.client:
        return _ClientListTile(
          client: client!,
          onTap: () => context.push('/trainer/clients/${client.id}'),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// List item model (tagged union for sectioned list)
// ---------------------------------------------------------------------------

enum _ListItemType { sectionHeader, divider, client }

class _ListItem {
  final _ListItemType type;
  final String? title;
  final Color? color;
  final Client? client;

  const _ListItem._({
    required this.type,
    this.title,
    this.color,
    this.client,
  });

  factory _ListItem.sectionHeader(String title, Color color) =>
      _ListItem._(
        type: _ListItemType.sectionHeader,
        title: title,
        color: color,
      );

  factory _ListItem.divider() => const _ListItem._(type: _ListItemType.divider);

  factory _ListItem.client(Client client) =>
      _ListItem._(type: _ListItemType.client, client: client);
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client List Tile — card style matching iOS ClientRow
// ---------------------------------------------------------------------------

class _ClientListTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const _ClientListTile({
    required this.client,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(client.status, theme);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage:
                    client.avatarPath != null && client.avatarPath!.isNotEmpty
                        ? NetworkImage(client.avatarPath!)
                        : null,
                child: client.avatarPath == null ||
                        client.avatarPath!.isEmpty
                    ? Text(
                        _initials(client.name),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (client.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.email!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  client.status.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'lead':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

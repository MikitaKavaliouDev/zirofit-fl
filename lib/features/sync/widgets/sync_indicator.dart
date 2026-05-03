import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/data/sync/sync_provider.dart';
import 'package:zirofit_fl/data/sync/sync_models.dart';

/// A small icon that reflects the current sync status.
///
/// Displays:
/// - A check icon when [SyncUiStatus.synced]
/// - A syncing indicator when [SyncUiStatus.syncing]
/// - An error icon when [SyncUiStatus.error]
/// - A pending icon when [SyncUiStatus.pending]
/// - An offline icon when [SyncUiStatus.offline]
class SyncIndicator extends ConsumerWidget {
  final double size;

  const SyncIndicator({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) => _buildIcon(status),
      loading: () => SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => Icon(Icons.cloud_off, size: size, color: Colors.grey),
    );
  }

  Widget _buildIcon(SyncUiStatus status) {
    switch (status) {
      case SyncUiStatus.synced:
        return Icon(Icons.cloud_done, size: size, color: Colors.green);
      case SyncUiStatus.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncUiStatus.pending:
        return Icon(Icons.cloud_upload, size: size, color: Colors.orange);
      case SyncUiStatus.error:
        return Icon(Icons.cloud_off, size: size, color: Colors.red);
      case SyncUiStatus.offline:
        return Icon(Icons.wifi_off, size: size, color: Colors.grey);
    }
  }
}

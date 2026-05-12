import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading placeholder for lists.
///
/// Each item mimics a ListTile with a leading circle avatar placeholder
/// and two text line placeholders. Uses a shimmer pulse effect via the
/// [shimmer] package.
///
/// {@tool dartpad}
/// ```dart
/// ListSkeleton(count: 3)
/// ```
/// {@end-tool}
///
/// Mirrors iOS [ListSkeleton].
class ListSkeleton extends StatelessWidget {
  /// Number of skeleton items to render (default: 5).
  final int count;

  /// Height of each skeleton row (default: 80).
  final double rowHeight;

  const ListSkeleton({
    super.key,
    this.count = 5,
    this.rowHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(count, (index) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: index == count - 1 ? 8 : 0,
            ),
            child: _buildSkeletonRow(context),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonRow(BuildContext context) {
    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Leading circle avatar placeholder
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          // Two text line placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title line
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle line
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

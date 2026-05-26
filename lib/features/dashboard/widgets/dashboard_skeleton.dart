import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading skeleton for the trainer dashboard.
///
/// Displays three placeholder sections that mirror the layout of the live
/// dashboard:
///   1. **Stats Row** — horizontally scrollable row of pill-shaped stat cards
///   2. **Quick Actions Row** — row of four equal-width action tiles
///   3. **Upcoming List** — vertical list of three upcoming-session rows
///
/// Mirrors iOS [DashboardSkeleton].
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // 1. Stats Row — horizontal scroll of pill-shaped stat cards
            // -----------------------------------------------------------------
            _buildSectionLabel(),
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 2. Quick Actions Row
            // -----------------------------------------------------------------
            _buildQuickActionsRow(),
            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // 3. Upcoming List
            // -----------------------------------------------------------------
            _buildUpcomingList(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section label placeholder
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel() {
    return Container(
      width: 100,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats row — 3 pill-shaped cards in a horizontal scroll
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) {
          return _buildStatCard();
        },
      ),
    );
  }

  Widget _buildStatCard() {
    return Container(
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle placeholder
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          // Metric value placeholder
          Container(
            width: 60,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // Label placeholder
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
    );
  }

  // ---------------------------------------------------------------------------
  // Quick actions row — 4 equal-width tiles
  // ---------------------------------------------------------------------------

  Widget _buildQuickActionsRow() {
    return SizedBox(
      height: 100,
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == 3 ? 0 : 6,
              ),
              child: _buildQuickActionTile(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickActionTile() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon placeholder
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          // Label placeholder
          Container(
            width: 40,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Upcoming list — 3 vertical rows
  // ---------------------------------------------------------------------------

  Widget _buildUpcomingList() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == 2 ? 0 : 10,
          ),
          child: _buildUpcomingRow(),
        );
      }),
    );
  }

  Widget _buildUpcomingRow() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 90,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Time badge placeholder
          Container(
            width: 50,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

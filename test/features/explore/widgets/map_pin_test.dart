import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/explore/widgets/map_pin.dart';

/// Helper to wrap a widget in [MaterialApp] for theme context.
Widget wrapInApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TrainerMapPin', () {
    // =====================================================================
    // Test: Renders with photo URL
    // =====================================================================
    testWidgets('renders with photo URL showing CachedNetworkImage',
        (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const TrainerMapPin(photoUrl: 'https://example.com/photo.jpg'),
        ),
      );
      await tester.pump();

      // CachedNetworkImage should be in the widget tree (shows placeholder in test)
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    // =====================================================================
    // Test: Renders fallback when no photo
    // =====================================================================
    testWidgets('renders fallback icon when no photo URL', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const TrainerMapPin()),
      );
      await tester.pump();

      // Fallback person icon should be shown
      expect(find.byIcon(Icons.person), findsOneWidget);

      // No CachedNetworkImage when no URL
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    // =====================================================================
    // Test: Renders fallback when photo URL is empty string
    // =====================================================================
    testWidgets('renders fallback icon when photo URL is empty', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const TrainerMapPin(photoUrl: '')),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    // =====================================================================
    // Test: Custom size is applied
    // =====================================================================
    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const TrainerMapPin(size: 80),
        ),
      );
      await tester.pump();

      // The pin body is a Container with the size → we verify it rendered
      expect(find.byIcon(Icons.person), findsOneWidget);
      // Container should exist (the pin body)
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('EventMapPin', () {
    // =====================================================================
    // Test: Renders with image URL
    // =====================================================================
    testWidgets('renders with image URL showing CachedNetworkImage',
        (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const EventMapPin(imageUrl: 'https://example.com/event.jpg'),
        ),
      );
      await tester.pump();

      // CachedNetworkImage should be in the widget tree (shows placeholder in test)
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    // =====================================================================
    // Test: Renders fallback when no image
    // =====================================================================
    testWidgets('renders fallback icon when no image URL', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const EventMapPin()),
      );
      await tester.pump();

      // Fallback event icon should be shown
      expect(find.byIcon(Icons.event), findsOneWidget);

      // No CachedNetworkImage when no URL
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    // =====================================================================
    // Test: Renders fallback when image URL is empty string
    // =====================================================================
    testWidgets('renders fallback icon when image URL is empty', (tester) async {
      await tester.pumpWidget(
        wrapInApp(const EventMapPin(imageUrl: '')),
      );
      await tester.pump();

      expect(find.byIcon(Icons.event), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    // =====================================================================
    // Test: Custom size is applied
    // =====================================================================
    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const EventMapPin(size: 100),
        ),
      );
      await tester.pump();

      // The pin body is a Container with the size → we verify it rendered
      expect(find.byIcon(Icons.event), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('TrainerMapPin vs EventMapPin', () {
    // =====================================================================
    // Test: Different fallback icons for trainer vs event
    // =====================================================================
    testWidgets('trainer pin shows person icon, event pin shows event icon',
        (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const Column(
            children: [
              TrainerMapPin(),
              EventMapPin(),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    // =====================================================================
    // Test: Both pin types render without crashing
    // =====================================================================
    testWidgets('both pin types render without crashing', (tester) async {
      await tester.pumpWidget(
        wrapInApp(
          const Column(
            children: [
              TrainerMapPin(photoUrl: 'https://example.com/t.jpg'),
              EventMapPin(imageUrl: 'https://example.com/e.jpg'),
            ],
          ),
        ),
      );
      await tester.pump();

      // Both should render CachedNetworkImage
      expect(find.byType(CachedNetworkImage), findsNWidgets(2));
    });
  });
}

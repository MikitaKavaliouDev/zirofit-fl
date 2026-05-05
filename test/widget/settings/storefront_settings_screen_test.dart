import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/settings/providers/storefront_provider.dart';
import 'package:zirofit_fl/features/settings/screens/storefront_settings_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakeStorefrontNotifier extends StorefrontNotifier {
  StorefrontState _s;
  FakeStorefrontNotifier(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  StorefrontState get state => _s;

  void emit(StorefrontState s) {
    _s = s;
    super.state = s;
  }

  @override
  Future<void> fetchStorefront() async {}

  @override
  Future<void> toggleVisibility() async {
    final newState = _s.copyWith(
      isVisible: !_s.isVisible,
      successMessage: !_s.isVisible
          ? 'Storefront is now visible'
          : 'Storefront is now hidden',
    );
    emit(newState);
  }

  @override
  Future<void> toggleFeatured() async {
    emit(_s.copyWith(
      isFeatured: !_s.isFeatured,
      successMessage: !_s.isFeatured
          ? 'Marked as featured'
          : 'Featured status removed',
    ));
  }
}

Widget buildApp(StorefrontState state) => ProviderScope(
      overrides: [
        storefrontProvider.overrideWith(
          (ref) => FakeStorefrontNotifier(state),
        ),
      ],
      child: const MaterialApp(home: StorefrontSettingsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('StorefrontSettingsScreen', () {
    testWidgets('renders settings form', (tester) async {
      await tester.pumpWidget(
        buildApp(const StorefrontState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Storefront Settings'), findsOneWidget);

      // Section headers
      expect(find.text('Storefront Visibility'), findsOneWidget);
      expect(find.text('Featured Status'), findsOneWidget);
      expect(find.text('Manage Content'), findsOneWidget);
      expect(find.text('Platform & Fees'), findsOneWidget);

      // Quick links
      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Packages'), findsOneWidget);
      expect(find.text('Testimonials'), findsOneWidget);
      expect(find.text('Transformation Photos'), findsOneWidget);

      // Platform fee
      expect(find.text('Ziro Platform Fee'), findsOneWidget);
      expect(find.text('5%'), findsOneWidget);
    });

    testWidgets('toggles visibility option', (tester) async {
      await tester.pumpWidget(
        buildApp(const StorefrontState(
          isLoading: false,
          isVisible: true,
        )),
      );
      await tester.pumpAndSettle();

      // Initially visible
      expect(find.text('Your storefront is visible'), findsOneWidget);
      // visibility icon appears in section header AND in the card
      expect(find.byIcon(Icons.visibility), findsAtLeast(1));

      // Find the visibility Switch (first of two switches)
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2)); // visibility + featured
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      // After toggle, should be hidden
      expect(find.text('Your storefront is hidden'), findsOneWidget);
      expect(find.text('Storefront is now hidden'), findsOneWidget);
    });

    testWidgets('toggles featured option', (tester) async {
      await tester.pumpWidget(
        buildApp(const StorefrontState(
          isLoading: false,
          isFeatured: false,
        )),
      );
      await tester.pumpAndSettle();

      // Initially not featured
      expect(find.text('Not Featured'), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsOneWidget);

      // Find and tap the featured Switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2)); // visibility + featured

      // Tap the second switch (featured)
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      // After toggle, should be featured
      expect(find.text('Featured Trainer'), findsOneWidget);
      expect(find.text('Marked as featured'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (tester) async {
      await tester.pumpWidget(
        buildApp(const StorefrontState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success message banner', (tester) async {
      await tester.pumpWidget(
        buildApp(const StorefrontState(
          isLoading: false,
          successMessage: 'Storefront is now visible',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Storefront is now visible'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows error message banner', (tester) async {
      await tester.pumpWidget(
        buildApp(const StorefrontState(
          isLoading: false,
          error: 'Something went wrong',
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}

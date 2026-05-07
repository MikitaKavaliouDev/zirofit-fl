import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_packages_screen.dart';
import '../../helpers/test_setup.dart';

class FakeTP extends TrainerProfileNotifier {
  TrainerProfileState _s;
  FakeTP(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }
  @override
  TrainerProfileState get state => _s;
  void emit(TrainerProfileState ns) {
    _s = ns;
    super.state = ns;
  }
  @override
  Future<void> fetchProfile() async {}

  @override
  Future<void> addPackage(Map<String, dynamic> data) async {
    final pkg = Package(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      numberOfSessions: data['numberOfSessions'] as int? ?? 1,
      isActive: state.packages.isEmpty,
      stripeProductId: '',
      stripePriceId: '',
      trainerId: 't1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(packages: [...state.packages, pkg]));
  }

  @override
  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    final updated = state.packages.map((p) {
      if (p.id == id) {
        return Package(
          id: p.id,
          name: data['name'] as String? ?? p.name,
          description: data['description'] as String? ?? p.description,
          price: (data['price'] as num?)?.toDouble() ?? p.price,
          numberOfSessions:
              data['numberOfSessions'] as int? ?? p.numberOfSessions,
          isActive: p.isActive,
          stripeProductId: p.stripeProductId,
          stripePriceId: p.stripePriceId,
          trainerId: p.trainerId,
          createdAt: p.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return p;
    }).toList();
    emit(state.copyWith(packages: updated));
  }

  @override
  Future<void> deletePackage(String id) async {
    emit(state.copyWith(
      packages: state.packages.where((p) => p.id != id).toList(),
    ));
  }

  @override
  Future<void> setDefaultPackage(String id) async {
    final updated = state.packages.map((p) {
      return Package(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        numberOfSessions: p.numberOfSessions,
        isActive: p.id == id,
        stripeProductId: p.stripeProductId,
        stripePriceId: p.stripePriceId,
        trainerId: p.trainerId,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        deletedAt: p.deletedAt,
      );
    }).toList();
    emit(state.copyWith(packages: updated));
  }

  @override
  Future<void> addService(Map<String, dynamic> data) async {}
  @override
  Future<void> updateService(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteService(String id) async {}
  @override
  Future<void> addTestimonial(Map<String, dynamic> data) async {}
  @override
  Future<void> deleteTestimonial(String id) async {}
  @override
  Future<void> addBenefit(Map<String, dynamic> data) async {}
  @override
  Future<void> deleteBenefit(String id) async {}
  @override
  void setActiveTab(int tab) {}
}

Widget buildTestApp(TrainerProfileState state) => ProviderScope(
      overrides: [
        trainerProfileProvider.overrideWith((ref) => FakeTP(state)),
      ],
      child: const MaterialApp(
        home: TrainerPackagesScreen(),
      ),
    );

Package makePackage({
  String id = '1',
  String name = '10-Session Bundle',
  String? description = 'Save on 10 sessions',
  double price = 500.0,
  int numberOfSessions = 10,
  bool isActive = false,
}) =>
    Package(
      id: id,
      name: name,
      description: description,
      price: price,
      numberOfSessions: numberOfSessions,
      isActive: isActive,
      stripeProductId: '',
      stripePriceId: '',
      trainerId: 't1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerPackagesScreen', () {
    testWidgets('Test 1: Shows packages list', (tester) async {
      final packages = [
        makePackage(id: '1', name: 'Starter Pack'),
        makePackage(id: '2', name: 'Premium Pack'),
      ];
      final state = TrainerProfileState(
        packages: packages,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Starter Pack'), findsOneWidget);
      expect(find.text('Premium Pack'), findsOneWidget);
      expect(find.text('Packages'), findsOneWidget);
    });

    testWidgets('Test 2: Add package form works', (tester) async {
      final state = TrainerProfileState(packages: [], isLoading: false);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Shows empty state
      expect(find.text('No packages yet'), findsOneWidget);

      // Tap Add button in AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear (both empty-state button and dialog title contain "Add Package")
      expect(find.text('Add Package'), findsAtLeastNWidgets(1));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Package Name *'),
        'New Package',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Great package deal',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price *'),
        '299',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sessions *'),
        '8',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('New Package'), findsOneWidget);
    });

    testWidgets('Test 3: Edit package updates correctly', (tester) async {
      final pkg = makePackage(id: '1', name: 'Old Name');
      final state = TrainerProfileState(packages: [pkg], isLoading: false);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Old Name'), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Package'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Package Name *'),
        'Updated Name',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Updated Name'), findsOneWidget);
      expect(find.text('Old Name'), findsNothing);
    });

    testWidgets('Test 4: Delete removes package', (tester) async {
      final pkg = makePackage(id: '1', name: 'To Delete');
      final state = TrainerProfileState(packages: [pkg], isLoading: false);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Package'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsNothing);
    });
  });
}

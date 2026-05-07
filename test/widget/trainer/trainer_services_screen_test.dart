import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_services_screen.dart';
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
  Future<void> addService(Map<String, dynamic> data) async {
    final service = Service(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      profileId: 'p1',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble(),
      duration: data['duration'] as int?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(services: [...state.services, service]));
  }

  @override
  Future<void> updateService(String id, Map<String, dynamic> data) async {
    final updated = state.services.map((s) {
      if (s.id == id) {
        return Service(
          id: s.id,
          profileId: s.profileId,
          title: data['title'] as String? ?? s.title,
          description: data['description'] as String? ?? s.description,
          price: (data['price'] as num?)?.toDouble() ?? s.price,
          duration: data['duration'] as int? ?? s.duration,
          createdAt: s.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    emit(state.copyWith(services: updated));
  }

  @override
  Future<void> deleteService(String id) async {
    emit(state.copyWith(
      services: state.services.where((s) => s.id != id).toList(),
    ));
  }

  @override
  Future<void> addPackage(Map<String, dynamic> data) async {}
  @override
  Future<void> updatePackage(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deletePackage(String id) async {}
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
        trainerProfileProvider
            .overrideWith((ref) => FakeTP(state)),
      ],
      child: const MaterialApp(
        home: TrainerServicesScreen(),
      ),
    );

Service makeService({
  String id = '1',
  String title = 'Personal Training',
  String description = 'One-on-one training session',
  double? price = 75.0,
  int? duration = 60,
}) =>
    Service(
      id: id,
      profileId: 'p1',
      title: title,
      description: description,
      price: price,
      duration: duration,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerServicesScreen', () {
    testWidgets('Test 1: Shows services list', (tester) async {
      final services = [
        makeService(id: '1', title: 'Personal Training'),
        makeService(id: '2', title: 'Nutrition Coaching'),
      ];
      final state = TrainerProfileState(
        services: services,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Personal Training'), findsOneWidget);
      expect(find.text('Nutrition Coaching'), findsOneWidget);
      expect(find.text('Services'), findsOneWidget);
    });

    testWidgets('Test 2: Add service form works', (tester) async {
      final state = TrainerProfileState(services: [], isLoading: false);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Shows empty state with Add Service button
      expect(find.text('No services yet'), findsOneWidget);

      // Tap the Add button in the AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear (dialog title + empty state button both contain "Add Service")
      expect(find.text('Add Service'), findsAtLeastNWidgets(1));

      // Fill in the form
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'New Service',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'A brand new service',
      );

      // Submit
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      // New service should appear in the list
      expect(find.text('New Service'), findsOneWidget);
    });

    testWidgets('Test 3: Edit service updates correctly', (tester) async {
      final service = makeService(id: '1', title: 'Old Title');
      final state = TrainerProfileState(
        services: [service],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Open popup menu via PopupMenuButton
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Edit dialog should appear
      expect(find.text('Edit Service'), findsOneWidget);

      // Clear and enter new title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name *'),
        'Updated Title',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Updated Title'), findsOneWidget);
      expect(find.text('Old Title'), findsNothing);
    });

    testWidgets('Test 4: Delete removes service', (tester) async {
      final service = makeService(id: '1', title: 'To Delete');
      final state = TrainerProfileState(
        services: [service],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      expect(find.text('Delete Service'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_testimonials_screen.dart';
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
  Future<void> addTestimonial(Map<String, dynamic> data) async {
    final testimonial = Testimonial(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      profileId: 'p1',
      clientName: data['clientName'] as String? ?? '',
      testimonialText: data['testimonialText'] as String? ?? '',
      rating: data['rating'] as int?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(
        testimonials: [...state.testimonials, testimonial]));
  }

  @override
  Future<void> deleteTestimonial(String id) async {
    emit(state.copyWith(
      testimonials:
          state.testimonials.where((t) => t.id != id).toList(),
    ));
  }

  @override
  Future<void> addService(Map<String, dynamic> data) async {}
  @override
  Future<void> updateService(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteService(String id) async {}
  @override
  Future<void> addPackage(Map<String, dynamic> data) async {}
  @override
  Future<void> updatePackage(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deletePackage(String id) async {}
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
        home: TrainerTestimonialsScreen(),
      ),
    );

Testimonial makeTestimonial({
  String id = '1',
  String clientName = 'John Doe',
  String testimonialText = 'Great trainer!',
  int? rating = 5,
}) =>
    Testimonial(
      id: id,
      profileId: 'p1',
      clientName: clientName,
      testimonialText: testimonialText,
      rating: rating,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerTestimonialsScreen', () {
    testWidgets('Test 1: Shows testimonials list', (tester) async {
      final testimonials = [
        makeTestimonial(
          id: '1',
          clientName: 'Alice',
          testimonialText: 'Amazing coach!',
        ),
        makeTestimonial(
          id: '2',
          clientName: 'Bob',
          testimonialText: 'Helped me reach my goals',
        ),
      ];
      final state = TrainerProfileState(
        testimonials: testimonials,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Amazing coach!'), findsOneWidget);
      expect(find.text('Testimonials'), findsOneWidget);
    });

    testWidgets('Test 2: Add testimonial form works', (tester) async {
      final state = TrainerProfileState(
          testimonials: [], isLoading: false);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Shows empty state
      expect(find.text('No testimonials yet'), findsOneWidget);

      // Tap Add button in AppBar
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Add Testimonial'), findsAtLeastNWidgets(1));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Client Name *'),
        'Jane Smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Testimonial *'),
        'Fantastic experience!',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('Test 3: Delete removes testimonial', (tester) async {
      final testimonial = makeTestimonial(
        id: '1',
        clientName: 'To Delete',
        testimonialText: 'Will be removed',
      );
      final state = TrainerProfileState(
        testimonials: [testimonial],
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Testimonial'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('To Delete'), findsNothing);
    });
  });
}

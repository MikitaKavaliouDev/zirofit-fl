import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/features/events/providers/trainer_events_provider.dart';
import 'package:zirofit_fl/features/events/screens/trainer_events_screen.dart';
import '../../helpers/test_setup.dart';

class FakeTrainerEventsNotifier extends TrainerEventsNotifier {
  final TrainerEventsState _state;
  FakeTrainerEventsNotifier(this._state) : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  TrainerEventsState get state => _state;

  @override
  Future<void> fetchEvents() async {}

  @override
  Future<bool> createEvent(Map<String, dynamic> data) async => false;

  @override
  Future<void> refresh() async {}
}

Widget buildApp(TrainerEventsState state) => ProviderScope(
      overrides: [
        trainerEventsProvider
            .overrideWith((ref) => FakeTrainerEventsNotifier(state)),
      ],
      child: const MaterialApp(home: TrainerEventsScreen()),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('TrainerEventsScreen', () {
    testWidgets('renders loading indicator when isLoading and empty list',
        (tester) async {
      await tester.pumpWidget(buildApp(const TrainerEventsState(isLoading: true)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state when error and empty list', (tester) async {
      await tester.pumpWidget(buildApp(const TrainerEventsState(error: 'Network error')));
      await tester.pump();
      expect(find.text('Failed to load events'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders empty state when no events', (tester) async {
      await tester.pumpWidget(buildApp(const TrainerEventsState()));
      await tester.pump();
      expect(find.text('No events yet'), findsOneWidget);
      expect(find.text('Create your first event to get started.'), findsOneWidget);
      expect(find.text('Create Event'), findsOneWidget);
    });

    testWidgets('renders list of events', (tester) async {
      final now = DateTime.now();
      final event = Event(
        id: 'e1',
        trainerId: 't1',
        title: 'Yoga Class',
        description: 'Relaxing yoga',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        locationName: 'Studio A',
        price: 50.0,
        currency: 'PLN',
        capacity: 20,
        enrolledCount: 5,
        category: 'Yoga',
        createdAt: now,
        updatedAt: now,
      );
      final state = TrainerEventsState(events: [event]);
      await tester.pumpWidget(buildApp(state));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Yoga Class'), findsOneWidget);
      expect(find.text('Studio A'), findsOneWidget);
      expect(find.text('50.00 PLN'), findsOneWidget);
      expect(find.text('5/20 · 15 left'), findsOneWidget);
    });

    testWidgets('refresh button exists', (tester) async {
      await tester.pumpWidget(buildApp(const TrainerEventsState()));
      await tester.pump();
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('floating action button exists', (tester) async {
      await tester.pumpWidget(buildApp(const TrainerEventsState()));
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
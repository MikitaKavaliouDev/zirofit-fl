import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';
import 'package:zirofit_fl/features/settings/screens/notification_settings_screen.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class FakePreferencesNotifier extends PreferencesNotifier {
  PreferencesState _s;

  int pushCallCount = 0;
  int emailCallCount = 0;
  int reminderCallCount = 0;
  int bookingCallCount = 0;
  int trainerInClientCallCount = 0;
  int clientInTrainerCallCount = 0;

  FakePreferencesNotifier(this._s) {
    super.state = _s;
  }

  @override
  PreferencesState get state => _s;

  void emit(PreferencesState s) {
    _s = s;
    super.state = s;
  }

  @override
  Future<void> loadPreferences() async {}

  @override
  Future<void> setPushNotifications(bool enabled) async {
    pushCallCount++;
    emit(_s.copyWith(pushNotifications: enabled));
  }

  @override
  Future<void> setEmailNotifications(bool enabled) async {
    emailCallCount++;
    emit(_s.copyWith(emailNotifications: enabled));
  }

  @override
  Future<void> setWorkoutReminders(bool enabled) async {
    reminderCallCount++;
    emit(_s.copyWith(workoutReminders: enabled));
  }

  @override
  Future<void> setBookingAlerts(bool enabled) async {
    bookingCallCount++;
    emit(_s.copyWith(bookingAlerts: enabled));
  }

  @override
  Future<void> setShowTrainerNotificationsInClientMode(
      bool enabled) async {
    trainerInClientCallCount++;
    emit(_s.copyWith(
        showTrainerNotificationsInClientMode: enabled));
  }

  @override
  Future<void> setShowClientNotificationsInTrainerMode(
      bool enabled) async {
    clientInTrainerCallCount++;
    emit(_s.copyWith(
        showClientNotificationsInTrainerMode: enabled));
  }
}

Widget buildApp(PreferencesState state) => ProviderScope(
      overrides: [
        preferencesProvider.overrideWith(
          (ref) => FakePreferencesNotifier(state),
        ),
      ],
      child: const MaterialApp(home: NotificationSettingsScreen()),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotificationSettingsScreen', () {
    testWidgets('shows loading spinner when isLoading', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders AppBar title', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
    });

    testWidgets('renders all notification toggles', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState()),
      );
      await tester.pumpAndSettle();

      // Section headers
      expect(find.text('Notification Channels'), findsOneWidget);
      expect(find.text('Cross-Profile Notifications'), findsOneWidget);

      // Channel toggles
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Receive push notifications on your device'),
          findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('Receive notifications via email'), findsOneWidget);
      expect(find.text('Workout Reminders'), findsOneWidget);
      expect(find.text('Get reminded about upcoming workouts'),
          findsOneWidget);
      expect(find.text('Booking Alerts'), findsOneWidget);
      expect(
        find.text(
            'Get notified about session bookings and changes'),
        findsOneWidget,
      );

      // Cross-profile toggles
      expect(
        find.text('Trainer Notifications in Client Mode'),
        findsOneWidget,
      );
      expect(find.text('Client Notifications in Trainer Mode'),
          findsOneWidget);
    });

    testWidgets('all toggles show correct initial values',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(
          pushNotifications: true,
          emailNotifications: false,
          workoutReminders: true,
          bookingAlerts: false,
          showTrainerNotificationsInClientMode: true,
          showClientNotificationsInTrainerMode: false,
        )),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      // 6 switches total
      expect(switches, findsNWidgets(6));

      // Check values
      expect(tester.widget<Switch>(switches.at(0)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(1)).value, isFalse);
      expect(tester.widget<Switch>(switches.at(2)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(3)).value, isFalse);
      expect(tester.widget<Switch>(switches.at(4)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(5)).value, isFalse);
    });

    testWidgets('tapping Push Notifications calls setPushNotifications',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(pushNotifications: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
              home: NotificationSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(notifier.pushCallCount, equals(1));
    });

    testWidgets('tapping Email Notifications calls setEmailNotifications',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(emailNotifications: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
              home: NotificationSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();

      expect(notifier.emailCallCount, equals(1));
    });

    testWidgets('tapping Workout Reminders calls setWorkoutReminders',
        (tester) async {
      final notifier = FakePreferencesNotifier(
        const PreferencesState(workoutReminders: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
              home: NotificationSettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();

      expect(notifier.reminderCallCount, equals(1));
    });

    testWidgets('shows error banner when error is set', (tester) async {
      await tester.pumpWidget(
        buildApp(const PreferencesState(
          error: 'Failed to save notification preferences',
        )),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to save notification preferences'),
        findsOneWidget,
      );
      // Error banner shows dismiss icon
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/explore/screens/public_trainer_profile_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

Profile _createDummyProfile({
  String id = 'trainer-1',
  String userId = 'user-1',
  String? aboutMe = 'Test Trainer',
  String? location = 'New York',
  double? averageRating = 4.5,
  List<String> specialties = const ['Strength', 'Cardio'],
  String? certifications = 'NASM',
  String? philosophy = 'Train hard',
  String? methodology = 'Progressive overload',
  double? minServicePrice = 50.0,
  String businessCurrency = 'USD',
}) {
  return Profile(
    id: id,
    userId: userId,
    aboutMe: aboutMe,
    location: location,
    averageRating: averageRating,
    specialties: specialties,
    certifications: certifications,
    philosophy: philosophy,
    methodology: methodology,
    minServicePrice: minServicePrice,
    businessCurrency: businessCurrency,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('Public trainer profile screen renders trainer profile info',
      (tester) async {
    final profile = _createDummyProfile();

    await tester.pumpApp(PublicTrainerProfileScreen(trainer: profile));
    await tester.pumpAndSettle();

    // Verify app bar title uses aboutMe
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Test Trainer'),
      ),
      findsOneWidget,
    );
    // Verify location
    expect(find.text('New York'), findsOneWidget);
    // Verify rating
    expect(find.text('4.5'), findsOneWidget);
    // Verify specialties
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Cardio'), findsOneWidget);
    // Verify certifications
    expect(find.text('NASM'), findsOneWidget);
    // Verify philosophy
    expect(find.text('Train hard'), findsOneWidget);
    // Verify methodology
    expect(find.text('Progressive overload'), findsOneWidget);
    // Verify price info
    expect(find.text('From 50.00 USD'), findsOneWidget);
  });

  testWidgets('Public trainer profile screen handles missing optional fields',
      (tester) async {
    final profile = _createDummyProfile(
      aboutMe: null,
      location: null,
      averageRating: null,
      specialties: [],
      certifications: null,
      philosophy: null,
      methodology: null,
      minServicePrice: null,
    );

    await tester.pumpApp(PublicTrainerProfileScreen(trainer: profile));
    await tester.pumpAndSettle();

    // Should still render with default values
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Trainer Profile'),
      ),
      findsOneWidget,
    );
    // No location, rating, etc.
    expect(find.text('New York'), findsNothing);
    expect(find.text('4.5'), findsNothing);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_profile_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/trainer_profile_screen.dart';
import '../../helpers/test_setup.dart';

class FakeTP extends TrainerProfileNotifier {
  TrainerProfileState _s;
  FakeTP(this._s) : super(apiClient: ApiClient.instance) { super.state = _s; }
  @override TrainerProfileState get state => _s;
  void emit(TrainerProfileState ns) { _s = ns; super.state = ns; }
  @override Future<void> fetchProfile() async {}
  @override Future<void> updateTextContent(String field, String content) async {}
  @override Future<void> addService(Map<String, dynamic> data) async {}
  @override Future<void> updateService(String id, Map<String, dynamic> data) async {}
  @override Future<void> deleteService(String id) async {}
  @override Future<void> addPackage(Map<String, dynamic> data) async {}
  @override Future<void> updatePackage(String id, Map<String, dynamic> data) async {}
  @override Future<void> deletePackage(String id) async {}
  @override Future<void> addTestimonial(Map<String, dynamic> data) async {}
  @override Future<void> deleteTestimonial(String id) async {}
  @override Future<void> addBenefit(Map<String, dynamic> data) async {}
  @override Future<void> deleteBenefit(String id) async {}
  @override void setActiveTab(int tab) {}
}

Widget b(TrainerProfileState s) => ProviderScope(overrides: [trainerProfileProvider.overrideWith((ref) => FakeTP(s))], child: const MaterialApp(home: TrainerProfileScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();

  testWidgets('loading', (t) async { await t.pumpWidget(b(const TrainerProfileState(isLoading: true))); await t.pump(); expect(find.byType(CircularProgressIndicator), findsOneWidget); });
  testWidgets('data', (t) async {
    final p = Profile(id: '1', userId: '1', completionPercentage: 75, createdAt: now, updatedAt: now);
    await t.pumpWidget(b(TrainerProfileState(profile: p, isLoading: false)));
    await t.pumpAndSettle();
    expect(find.text('Trainer Profile'), findsOneWidget);
    expect(find.text('Core Info'), findsOneWidget);
    expect(find.text('75% complete'), findsOneWidget);
  });
  testWidgets('error', (t) async {
    await t.pumpWidget(b(const TrainerProfileState(isLoading: false, error: 'err')));
    await t.pumpAndSettle();
    expect(find.text('Trainer Profile'), findsOneWidget);
  });
}

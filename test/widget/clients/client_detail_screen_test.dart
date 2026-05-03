import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/features/clients/providers/client_detail_provider.dart';
import 'package:zirofit_fl/features/clients/screens/client_detail_screen.dart';
import '../../helpers/test_setup.dart';

class Fake extends ClientDetailNotifier {
  final ClientDetailState _s;
  Fake(this._s, {required String cid}) : super(apiClient: ApiClient.instance, clientId: cid) { super.state = _s; }
  @override ClientDetailState get state => _s;
  @override Future<void> fetchAll() async {}
  @override Future<void> fetchClient() async {}
  @override Future<void> fetchMeasurements() async {}
  @override Future<void> fetchPhotos() async {}
  @override Future<void> fetchSessions() async {}
  @override Future<String?> addMeasurement({required DateTime measurementDate, double? weightKg, double? bodyFatPercentage, String? notes}) async => null;
  @override Future<String?> uploadPhoto({required String imagePath, DateTime? photoDate, String? caption}) async => null;
}

Widget b(ClientDetailState s) => ProviderScope(
  overrides: [clientDetailProvider.overrideWith((ref, String clientId) => Fake(s, cid: clientId))],
  child: const MaterialApp(home: ClientDetailScreen(id: 'test')),
);

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();
  testWidgets('loading', (t) async { await t.pumpWidget(b(const ClientDetailState(isLoadingClient: true))); await t.pump(); expect(find.byType(CircularProgressIndicator), findsOneWidget); });
  testWidgets('data', (t) async {
    final c = Client(id: 'test', name: 'JD', email: 'j@j.com', status: 'active', createdAt: now, updatedAt: now);
    await t.pumpWidget(b(ClientDetailState(client: c, isLoadingClient: false, isLoadingMeasurements: false, isLoadingPhotos: false, isLoadingSessions: false)));
    await t.pump(); await t.pump(const Duration(milliseconds: 500));
    // "JD" appears in both AppBar title and header
    expect(find.text('JD'), findsAtLeastNWidgets(1));
    expect(find.text('Overview'), findsOneWidget);
  });
  testWidgets('error', (t) async {
    await t.pumpWidget(b(const ClientDetailState(isLoadingClient: false, error: 'err')));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Try Again'), findsOneWidget);
  });
}

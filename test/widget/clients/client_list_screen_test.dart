import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';
import 'package:zirofit_fl/features/clients/screens/client_list_screen.dart';
import '../../helpers/test_setup.dart';

class FakeClientListNotifier extends ClientListNotifier {
  ClientListState _state;
  FakeClientListNotifier(this._state) : super(apiClient: ApiClient.instance) { super.state = _state; }
  @override ClientListState get state => _state;
  void emit(ClientListState ns) { _state = ns; super.state = ns; }
  @override Future<void> fetchClients({String? search}) async {}
  @override void setSearch(String query) {}
  @override Future<String?> inviteClient({required String name, required String email}) async => null;
}

Widget b(ClientListState s) => ProviderScope(overrides: [clientListProvider.overrideWith((ref) => FakeClientListNotifier(s))], child: const MaterialApp(home: ClientListScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  final now = DateTime.now();

  testWidgets('loading', (t) async { await t.pumpWidget(b(const ClientListState(isLoading: true))); await t.pump(); expect(find.byType(CircularProgressIndicator), findsOneWidget); });
  testWidgets('data', (t) async {
    final cs = [Client(id: '1', name: 'John Doe', status: 'active', createdAt: now, updatedAt: now)];
    await t.pumpWidget(b(ClientListState(clients: cs, filteredClients: cs, isLoading: false)));
    await t.pumpAndSettle();
    expect(find.text('John Doe'), findsOneWidget);
  });
  testWidgets('error', (t) async {
    await t.pumpWidget(b(const ClientListState(error: 'err', isLoading: false)));
    await t.pumpAndSettle();
    expect(find.text('Try Again'), findsOneWidget);
  });
  testWidgets('empty', (t) async {
    await t.pumpWidget(b(const ClientListState(isLoading: false)));
    await t.pumpAndSettle();
    expect(find.textContaining('No clients yet'), findsOneWidget);
  });
}

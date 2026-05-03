import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/resource.dart';
import 'package:zirofit_fl/features/resources/providers/resource_provider.dart';
import 'package:zirofit_fl/features/resources/screens/resource_vault_screen.dart';
import '../../helpers/test_setup.dart';

class FakeResourceNotifier extends ResourceNotifier {
  ResourcesState _state;
  FakeResourceNotifier(this._state) : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  ResourcesState get state => _state;

  void emit(ResourcesState s) {
    _state = s;
    super.state = s;
  }

  @override
  Future<void> fetchResources() async {}
}

Widget buildApp(ResourcesState state) {
  return ProviderScope(
    overrides: [
      resourcesProvider.overrideWith(
        (ref) => FakeResourceNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: ResourceVaultScreen(),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('ResourceVaultScreen', () {
    final now = DateTime.now();

    testWidgets('shows loading indicator when isLoading and resources empty',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const ResourcesState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        buildApp(const ResourcesState(error: 'Something went wrong')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows empty state when no resources', (tester) async {
      await tester.pumpWidget(
        buildApp(const ResourcesState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No resources yet'), findsOneWidget);
      expect(
        find.textContaining('Add your first resource'),
        findsOneWidget,
      );
    });

    testWidgets('shows list of resources in data state', (tester) async {
      final resources = [
        Resource(
          id: '1',
          trainerId: 't1',
          title: 'Workout Plan PDF',
          description: 'A complete workout plan',
          fileUrl: 'https://example.com/workout.pdf',
          fileType: 'pdf',
          createdAt: now,
          updatedAt: now,
        ),
        Resource(
          id: '2',
          trainerId: 't1',
          title: 'Nutrition Guide',
          description: 'Healthy eating tips',
          fileUrl: 'https://example.com/guide.pdf',
          fileType: 'pdf',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ResourcesState(resources: resources, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workout Plan PDF'), findsOneWidget);
      expect(find.text('Nutrition Guide'), findsOneWidget);
      expect(find.text('A complete workout plan'), findsOneWidget);
      expect(find.text('Healthy eating tips'), findsOneWidget);
    });

    testWidgets('shows FAB for creating resources', (tester) async {
      await tester.pumpWidget(
        buildApp(const ResourcesState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows resources without description gracefully',
        (tester) async {
      final resources = [
        Resource(
          id: '3',
          trainerId: 't1',
          title: 'Minimal Resource',
          fileUrl: 'https://example.com/min.pdf',
          fileType: 'pdf',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ResourcesState(resources: resources, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal Resource'), findsOneWidget);
      // ListTile should not have a subtitle since description is null
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });

    testWidgets('shows file type badge on resource tiles', (tester) async {
      final resources = [
        Resource(
          id: '1',
          trainerId: 't1',
          title: 'My PDF',
          fileUrl: 'https://example.com/doc.pdf',
          fileType: 'pdf',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ResourcesState(resources: resources, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDF'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('shows appropriate icon for different file types',
        (tester) async {
      final resources = [
        Resource(
          id: '1',
          trainerId: 't1',
          title: 'Video',
          fileUrl: 'https://example.com/vid.mp4',
          fileType: 'video',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(ResourcesState(resources: resources, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.video_file), findsOneWidget);
    });
  });
}

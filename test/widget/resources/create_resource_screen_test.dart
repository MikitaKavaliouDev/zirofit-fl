import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/resources/screens/create_resource_screen.dart';
import 'package:zirofit_fl/features/resources/providers/resource_provider.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/data/models/resource.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// Fake ResourceNotifier that overrides createResource to avoid real API calls.
class FakeResourceNotifier extends ResourceNotifier {
  FakeResourceNotifier({super.apiClient});

  @override
  Future<Resource> createResource(Map<String, dynamic> data) async {
    // Return a dummy resource
    return Resource(
      id: 'new-resource',
      trainerId: 'trainer-1',
      title: data['title'] ?? 'New Resource',
      description: data['description'],
      fileType: data['file_type'] ?? 'pdf',
      fileUrl: data['file_url'] ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  late MockApiClient mockApiClient;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
  });

  group('CreateResourceScreen', () {
    testWidgets('renders form fields and button', (tester) async {
      await tester.pumpApp(
        const CreateResourceScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          resourcesProvider.overrideWith(
            (ref) => FakeResourceNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // App bar title and button both have "Create Resource" text
      expect(find.text('Create Resource'), findsNWidgets(2));

      // Title field
      expect(find.widgetWithText(TextFormField, 'Title'), findsOneWidget);
      expect(find.text('e.g. Workout Plan PDF'), findsOneWidget);

      // Description field
      expect(find.widgetWithText(TextFormField, 'Description (optional)'), findsOneWidget);
      expect(find.text('Brief description of the resource'), findsOneWidget);

      // File type dropdown
      expect(find.text('File Type'), findsOneWidget);

      // File URL field
      expect(find.widgetWithText(TextFormField, 'File URL'), findsOneWidget);
      expect(find.text('https://example.com/resource.pdf'), findsOneWidget);

      // Submit button
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('validation shows error when title is empty', (tester) async {
      await tester.pumpApp(
        const CreateResourceScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          resourcesProvider.overrideWith(
            (ref) => FakeResourceNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // Tap submit button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Expect validation error for title
      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('validation shows error when file URL is empty', (tester) async {
      await tester.pumpApp(
        const CreateResourceScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          resourcesProvider.overrideWith(
            (ref) => FakeResourceNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // Enter title to pass title validation
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Test Resource');
      // Tap submit button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Expect validation error for file URL
      expect(find.text('Please enter a file URL'), findsOneWidget);
    });
  });
}

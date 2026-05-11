import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/text_content.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_text_content_provider.dart';
import 'package:zirofit_fl/features/trainer/screens/edit_profile_text_screen.dart';
import '../../helpers/test_setup.dart';

class FakeTextContent extends TrainerTextContentNotifier {
  TrainerTextContentState _s;
  FakeTextContent(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }
  @override
  TrainerTextContentState get state => _s;
  void emit(TrainerTextContentState ns) {
    _s = ns;
    super.state = ns;
  }
  @override
  Future<void> fetchTextContent() async {}
  @override
  void updateField(String field, String value) {
    final current = _s.textContent;
    if (current == null) return;
    final updated = current.copyWith(
      aboutMe: field == 'aboutMe' ? value : null,
      philosophy: field == 'philosophy' ? value : null,
      methodology: field == 'methodology' ? value : null,
      certifications: field == 'certifications' ? value : null,
      qualifications: field == 'qualifications' ? value : null,
    );
    emit(_s.copyWith(textContent: updated));
  }
  @override
  Future<void> saveTextContent() async {
    emit(_s.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    await Future.delayed(Duration.zero);
    emit(_s.copyWith(
      isSaving: false,
      successMessage: 'Text content saved successfully',
    ));
  }
  @override
  Set<String> get dirtyFields => {};
  @override
  bool get hasDirtyFields => false;
}

Widget buildTestApp(TrainerTextContentState state) => ProviderScope(
      overrides: [
        trainerTextContentProvider
            .overrideWith((ref) => FakeTextContent(state)),
      ],
      child: const MaterialApp(
        home: EditProfileTextScreen(),
      ),
    );

TextContent makeTextContent({
  String aboutMe = 'About me text',
  String philosophy = 'My philosophy',
  String methodology = 'My methodology',
  String certifications = 'CPT, CSCS',
  String qualifications = 'BS Degree',
}) =>
    TextContent(
      aboutMe: aboutMe,
      philosophy: philosophy,
      methodology: methodology,
      certifications: certifications,
      qualifications: qualifications,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

void main() {
  setUpAll(() => configureTestApiClient());

  group('EditProfileTextScreen', () {
    // -----------------------------------------------------------------------
    // Test 1: Shows all text sections
    // -----------------------------------------------------------------------
    testWidgets('Test 1: Shows all text sections', (tester) async {
      final tc = makeTextContent();
      final state = TrainerTextContentState(
        textContent: tc,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Verify all section titles are visible
      expect(find.text('About Me / Bio'), findsOneWidget);
      expect(find.text('Philosophy'), findsOneWidget);
      expect(find.text('Methodology'), findsOneWidget);
      expect(find.text('Certifications'), findsOneWidget);
      expect(find.text('Qualifications'), findsOneWidget);

      // Verify content is populated
      expect(find.text('About me text'), findsOneWidget);
      expect(find.text('My philosophy'), findsOneWidget);
      expect(find.text('My methodology'), findsOneWidget);
      expect(find.text('CPT, CSCS'), findsOneWidget);
      expect(find.text('BS Degree'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 2: Character count displayed
    // -----------------------------------------------------------------------
    testWidgets('Test 2: Character count displayed for limited fields',
        (tester) async {
      final tc = makeTextContent(aboutMe: 'Short');
      final state = TrainerTextContentState(
        textContent: tc,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Find the About Me / Bio section and check counter
      // The counter text should show "5/500" for "Short"
      expect(find.text('5/500'), findsOneWidget);
    });

    testWidgets('Test 2b: Character count updates on typing', (tester) async {
      final tc = makeTextContent(aboutMe: '');
      final state = TrainerTextContentState(
        textContent: tc,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Initially 0/500
      expect(find.text('0/500'), findsOneWidget);

      // Type in the bio field
      final bioField = find.widgetWithText(TextFormField, '');
      await tester.enterText(bioField, 'Hello World');
      await tester.pumpAndSettle();

      // Should show 11/500
      expect(find.text('11/500'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Test 3: Save button calls provider
    // -----------------------------------------------------------------------
    testWidgets('Test 3: Save button triggers save', (tester) async {
      final tc = makeTextContent();
      final state = TrainerTextContentState(
        textContent: tc,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Find the save button in the app bar (check icon)
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Should show success message
      expect(
        find.text('Text content saved successfully'),
        findsOneWidget,
      );
    });

    testWidgets('Test 3b: Bottom save button also works', (tester) async {
      final tc = makeTextContent();
      final state = TrainerTextContentState(
        textContent: tc,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Scroll down to find the bottom save button
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Save All'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save All'));
      await tester.pumpAndSettle();

      expect(
        find.text('Text content saved successfully'),
        findsOneWidget,
      );
    });

    // -----------------------------------------------------------------------
    // Test 4: Validation prevents empty bio
    // -----------------------------------------------------------------------
    testWidgets('Test 4: Validation prevents empty bio', (tester) async {
      final tc = makeTextContent(aboutMe: 'NotEmpty');
      final state = TrainerTextContentState(
        textContent: tc,
        isLoading: false,
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Clear the bio field
      final bioField = find.widgetWithText(TextFormField, 'NotEmpty');
      await tester.tap(bioField);
      await tester.pumpAndSettle();

      // Select all and delete
      await tester.enterText(bioField, '');
      await tester.pumpAndSettle();

      // Tap save to trigger validation
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Bio cannot be empty'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Loading and error states
    // -----------------------------------------------------------------------
    testWidgets('Shows loading indicator when loading with no data',
        (tester) async {
      const state = TrainerTextContentState(isLoading: true);

      await tester.pumpWidget(buildTestApp(state));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Shows error with retry button', (tester) async {
      const state = TrainerTextContentState(
        isLoading: false,
        error: 'Failed to load',
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/text_content.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_text_content_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerTextContentNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerTextContentNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  TextContent createTextContent({
    String? aboutMe = 'I am a certified trainer',
    String? philosophy = 'Health first',
    String? methodology = 'Science-based approach',
    String? certifications = 'CPT, CSCS',
    String? qualifications = 'BS in Exercise Science',
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

  void stubFetchSuccess({TextContent? textContent}) {
    final tc = textContent ?? createTextContent();
    when(() => mockApiClient.get<TextContent>(
          ApiConstants.profileMeTextContent,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenAnswer((_) async => tc);
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  test('initial state has loading false and null text content', () {
    expect(notifier.state.isLoading, false);
    expect(notifier.state.isSaving, false);
    expect(notifier.state.textContent, isNull);
    expect(notifier.state.error, isNull);
    expect(notifier.state.successMessage, isNull);
  });

  // ---------------------------------------------------------------------------
  // Test 1: fetch populates all text fields
  // ---------------------------------------------------------------------------

  test('fetchTextContent populates all text fields on success', () async {
    stubFetchSuccess();

    await notifier.fetchTextContent();

    expect(notifier.state.isLoading, false);
    expect(notifier.state.textContent, isNotNull);
    expect(notifier.state.textContent!.aboutMe, 'I am a certified trainer');
    expect(notifier.state.textContent!.philosophy, 'Health first');
    expect(notifier.state.textContent!.methodology, 'Science-based approach');
    expect(notifier.state.textContent!.certifications, 'CPT, CSCS');
    expect(notifier.state.textContent!.qualifications,
        'BS in Exercise Science');
    expect(notifier.hasDirtyFields, false);
  });

  test('fetchTextContent sets error on failure', () async {
    when(() => mockApiClient.get<TextContent>(
          ApiConstants.profileMeTextContent,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenThrow(Exception('Server error'));

    await notifier.fetchTextContent();

    expect(notifier.state.isLoading, false);
    expect(notifier.state.error, isNotNull);
    expect(notifier.state.textContent, isNull);
  });

  // ---------------------------------------------------------------------------
  // Test 2: save sends all fields
  // ---------------------------------------------------------------------------

  test('saveTextContent sends all fields on PUT', () async {
    stubFetchSuccess();
    await notifier.fetchTextContent();

    when(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: any(named: 'body'),
        )).thenAnswer((_) async => {});

    await notifier.saveTextContent();

    expect(notifier.state.isSaving, false);
    expect(notifier.state.successMessage, isNotNull);

    verify(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: {
            'about_me': 'I am a certified trainer',
            'philosophy': 'Health first',
            'methodology': 'Science-based approach',
            'certifications': 'CPT, CSCS',
            'qualifications': 'BS in Exercise Science',
          },
        )).called(1);
  });

  test('saveTextContent sets error on failure', () async {
    stubFetchSuccess();
    await notifier.fetchTextContent();

    when(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: any(named: 'body'),
        )).thenThrow(Exception('Save failed'));

    await notifier.saveTextContent();

    expect(notifier.state.isSaving, false);
    expect(notifier.state.error, isNotNull);
  });

  // ---------------------------------------------------------------------------
  // Test 3: partial update only sends changed fields
  // ---------------------------------------------------------------------------

  test('savePartial sends only changed fields', () async {
    stubFetchSuccess();
    await notifier.fetchTextContent();

    // Modify only the philosophy field
    notifier.updateField('philosophy', 'Updated philosophy');

    when(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: any(named: 'body'),
        )).thenAnswer((_) async => {});

    await notifier.savePartial();

    expect(notifier.state.isSaving, false);

    // Verify only the changed field was sent
    verify(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: {
            'philosophy': 'Updated philosophy',
          },
        )).called(1);
  });

  test('savePartial sends multiple changed fields', () async {
    stubFetchSuccess();
    await notifier.fetchTextContent();

    // Modify two fields
    notifier.updateField('aboutMe', 'Updated bio');
    notifier.updateField('methodology', 'Updated methodology');

    when(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: any(named: 'body'),
        )).thenAnswer((_) async => {});

    await notifier.savePartial();

    verify(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: {
            'about_me': 'Updated bio',
            'methodology': 'Updated methodology',
          },
        )).called(1);
  });

  test('savePartial does nothing when no fields changed', () async {
    stubFetchSuccess();
    await notifier.fetchTextContent();

    when(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: any(named: 'body'),
        )).thenAnswer((_) async => {});

    await notifier.savePartial();

    // Verify the put was never called since there are no dirty fields
    verifyNever(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: any(named: 'body'),
        ));

    expect(notifier.state.successMessage, 'No changes to save');
  });

  test('updateField tracks dirty fields correctly', () async {
    stubFetchSuccess();
    await notifier.fetchTextContent();

    expect(notifier.hasDirtyFields, false);

    notifier.updateField('aboutMe', 'New bio');
    expect(notifier.hasDirtyFields, true);
    expect(notifier.dirtyFields, contains('aboutMe'));

    // Reset to original value should clear dirty
    notifier.updateField('aboutMe', 'I am a certified trainer');
    expect(notifier.hasDirtyFields, false);
  });

  // ---------------------------------------------------------------------------
  // Test 4: error handling
  // ---------------------------------------------------------------------------

  test('error is cleared on new fetch', () async {
    when(() => mockApiClient.get<TextContent>(
          ApiConstants.profileMeTextContent,
          queryParams: any(named: 'queryParams'),
          fromJson: any(named: 'fromJson'),
        )).thenThrow(Exception('First error'));

    await notifier.fetchTextContent();
    expect(notifier.state.error, isNotNull);

    // Stub success for second call
    stubFetchSuccess();
    await notifier.fetchTextContent();

    expect(notifier.state.error, isNull);
    expect(notifier.state.textContent, isNotNull);
  });

  test('error message is cleared on field update', () async {
    stubFetchSuccess();
    await notifier.fetchTextContent();

    when(() => mockApiClient.put(
          ApiConstants.profileMeTextContent,
          body: any(named: 'body'),
        )).thenThrow(Exception('Save error'));

    await notifier.saveTextContent();
    expect(notifier.state.error, isNotNull);

    notifier.updateField('aboutMe', 'Fixed text');

    expect(notifier.state.error, isNull);
  });
}

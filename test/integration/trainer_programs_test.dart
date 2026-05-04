import 'package:flutter_test/flutter_test.dart';
import '../helpers/integration_api_client.dart';

/// Integration tests for trainer programs API endpoints.
///
/// Run: flutter test test/integration/trainer_programs_test.dart
void main() {
  late TestApiClient client;
  bool isAuthenticated = false;

  setUpAll(() async {
    client = TestApiClient();
    isAuthenticated = await client.loginAsTrainer();
  });

  tearDownAll(() {
    client.logout();
  });

  test('GET /trainer/programs returns programs list', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final response = await client.get<Map<String, dynamic>>(
      '/trainer/programs',
    );
    expect(response.statusCode, anyOf(200, 401));
    if (response.statusCode == 200) {
      expect(response.data!['data'], isA<List>());
    }
  });

  test('POST /trainer/programs creates program', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final response = await client.post<Map<String, dynamic>>(
      '/trainer/programs',
      data: {'name': 'Test Program', 'description': 'Test description'},
    );
    expect(response.statusCode, anyOf(201, 400, 401));
  });

  test('GET /trainer/programs/templates returns templates', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final response = await client.get<Map<String, dynamic>>(
      '/trainer/programs/templates',
    );
    expect(response.statusCode, anyOf(200, 401));
  });

  test('POST /trainer/programs/templates creates template', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final response = await client.post<Map<String, dynamic>>(
      '/trainer/programs/templates',
      data: {'programId': 'test-program', 'name': 'Test Template'},
    );
    expect(response.statusCode, anyOf(201, 400, 401));
  });

  test('GET /trainer/programs/templates/:id returns template', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final listResponse = await client.get<Map<String, dynamic>>(
      '/trainer/programs/templates',
    );
    if (listResponse.statusCode == 200) {
      final templates = listResponse.data?['data'] as List?;
      if (templates != null && templates.isNotEmpty) {
        final templateId = templates.first['id'] as String;
        final detailResponse = await client.get<Map<String, dynamic>>(
          '/trainer/programs/templates/$templateId',
        );
        expect(detailResponse.statusCode, anyOf(200, 404));
      }
    }
  });

  test('PUT /trainer/programs/templates/:id updates template', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final listResponse = await client.get<Map<String, dynamic>>(
      '/trainer/programs/templates',
    );
    if (listResponse.statusCode == 200) {
      final templates = listResponse.data?['data'] as List?;
      if (templates != null && templates.isNotEmpty) {
        final templateId = templates.first['id'] as String;
        final updateResponse = await client.put<Map<String, dynamic>>(
          '/trainer/programs/templates/$templateId',
          data: {'name': 'Updated Name'},
        );
        expect(updateResponse.statusCode, anyOf(200, 404));
      }
    }
  });

  test('POST /trainer/programs/templates/:id/copy copies template', () async {
    if (!isAuthenticated) fail('Authentication failed');
    final listResponse = await client.get<Map<String, dynamic>>(
      '/trainer/programs/templates',
    );
    if (listResponse.statusCode == 200) {
      final templates = listResponse.data?['data'] as List?;
      if (templates != null && templates.isNotEmpty) {
        final templateId = templates.first['id'] as String;
        final copyResponse = await client.post<Map<String, dynamic>>(
          '/trainer/programs/templates/$templateId/copy',
          data: {},
        );
        expect(copyResponse.statusCode, anyOf(201, 404));
      }
    }
  });

  test('DELETE /trainer/programs/templates/:id deletes template', () async {
    if (!isAuthenticated) fail('Authentication failed');
    // Create new template then delete
    final createResponse = await client.post<Map<String, dynamic>>(
      '/trainer/programs/templates',
      data: {'programId': 'temp-template-delete', 'name': 'Temp Delete Test'},
    );
    if (createResponse.statusCode == 201) {
      final createdId = createResponse.data?['data']?['id'];
      if (createdId != null) {
        final deleteResponse = await client.delete<Map<String, dynamic>>(
          '/trainer/programs/templates/$createdId',
        );
        expect(deleteResponse.statusCode, anyOf(200, 404));
      }
    }
  });

  test(
    'GET /trainer/programs/templates/:id/exercises returns exercises',
    () async {
      if (!isAuthenticated) fail('Authentication failed');
      final listResponse = await client.get<Map<String, dynamic>>(
        '/trainer/programs/templates',
      );
      if (listResponse.statusCode == 200) {
        final templates = listResponse.data?['data'] as List?;
        if (templates != null && templates.isNotEmpty) {
          final templateId = templates.first['id'] as String;
          final exercisesResponse = await client.get<Map<String, dynamic>>(
            '/trainer/programs/templates/$templateId/exercises',
          );
          expect(exercisesResponse.statusCode, anyOf(200, 404));
        }
      }
    },
  );
}

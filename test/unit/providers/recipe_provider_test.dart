import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/nutrition/providers/recipe_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late RecipeNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = RecipeNotifier(apiClient: mockApiClient);
  });

  group('RecipeNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has empty recipes, not loading, no error, not saving', () {
      final state = notifier.state;
      expect(state.recipes, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSaving, false);
      expect(state.successMessage, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchRecipes
    // ---------------------------------------------------------------------------
    test('fetchRecipes sets loading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      final future = notifier.fetchRecipes();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchRecipes populates list on success', () async {
      final recipeJson = <String, dynamic>{
        'id': 'recipe-1',
        'trainer_id': 'trainer-1',
        'name': 'Grilled Chicken Salad',
        'description': 'A healthy salad',
        'instructions': 'Mix and serve',
        'protein_g': 30.0,
        'carbs_g': 10.0,
        'fat_g': 5.0,
        'calories': 350,
        'difficulty': 'easy',
        'prep_time': 10,
        'cook_time': 15,
        'is_published': true,
        'created_at': 1700000000000,
        'updated_at': 1700000000000,
      };

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [recipeJson],
          });

      await notifier.fetchRecipes();

      final state = notifier.state;
      expect(state.recipes.length, 1);
      expect(state.recipes[0].id, 'recipe-1');
      expect(state.recipes[0].name, 'Grilled Chicken Salad');
      expect(state.recipes[0].description, 'A healthy salad');
      expect(state.recipes[0].proteinG, 30.0);
      expect(state.recipes[0].carbsG, 10.0);
      expect(state.recipes[0].fatG, 5.0);
      expect(state.recipes[0].calories, 350);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('fetchRecipes populates multiple recipes', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'name': 'Recipe A',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 'r2',
                'trainer_id': 't1',
                'name': 'Recipe B',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchRecipes();

      expect(notifier.state.recipes.length, 2);
      expect(notifier.state.recipes[0].name, 'Recipe A');
      expect(notifier.state.recipes[1].name, 'Recipe B');
    });

    test('fetchRecipes handles empty data list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchRecipes();

      expect(notifier.state.recipes, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchRecipes handles missing data key', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.fetchRecipes();

      expect(notifier.state.recipes, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('fetchRecipes sets error on DioException with error message', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Internal server error'},
          },
        ),
      ));

      await notifier.fetchRecipes();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, 'Internal server error');
      expect(state.recipes, isEmpty);
    });

    test('fetchRecipes sets error on DioException with message field', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
          statusCode: 400,
          data: <String, dynamic>{'message': 'Bad request'},
        ),
      ));

      await notifier.fetchRecipes();

      expect(notifier.state.error, 'Bad request');
    });

    test('fetchRecipes handles connection timeout', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
      ));

      await notifier.fetchRecipes();

      expect(
        notifier.state.error,
        'Connection timeout. Please try again.',
      );
    });

    test('fetchRecipes handles network error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
      ));

      await notifier.fetchRecipes();

      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });

    test('fetchRecipes handles non-Dio exception', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Unexpected error'));

      await notifier.fetchRecipes();

      expect(notifier.state.error, 'Exception: Unexpected error');
    });

    // ---------------------------------------------------------------------------
    // createRecipe
    // ---------------------------------------------------------------------------
    test('createRecipe sends POST and returns recipe on success', () async {
      final responseJson = <String, dynamic>{
        'data': {
          'id': 'new-recipe',
          'trainer_id': 'trainer-1',
          'name': 'New Recipe',
          'description': 'A new recipe',
          'created_at': 1700000000000,
          'updated_at': 1700000000000,
        },
      };

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            body: any(named: 'body'),
          )).thenAnswer((_) async => responseJson);

      final recipe = await notifier.createRecipe({'name': 'New Recipe'});

      expect(recipe, isNotNull);
      expect(recipe.id, 'new-recipe');
      expect(recipe.name, 'New Recipe');
      expect(recipe.description, 'A new recipe');
      expect(notifier.state.recipes.length, 1);
      expect(notifier.state.recipes[0].name, 'New Recipe');
      expect(notifier.state.isSaving, false);
    });

    test('createRecipe sets isSaving before and after', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'r2',
              'trainer_id': 't1',
              'name': 'Saving Test',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      final future = notifier.createRecipe({'name': 'Saving Test'});
      expect(notifier.state.isSaving, isTrue);
      await future;
      expect(notifier.state.isSaving, isFalse);
    });

    test('createRecipe throws and sets error on DioException', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerRecipes),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Creation failed'},
          },
        ),
      ));

      expect(
        () => notifier.createRecipe({'name': 'Fail'}),
        throwsA(isA<DioException>()),
      );
      expect(notifier.state.error, 'Creation failed');
    });

    test('createRecipe appends to existing recipes', () async {
      // First populate with one recipe
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'existing',
                'trainer_id': 't1',
                'name': 'Existing',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchRecipes();
      expect(notifier.state.recipes.length, 1);

      // Then create a new one
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'new',
              'trainer_id': 't1',
              'name': 'New Recipe',
              'created_at': 1700000000000,
              'updated_at': 1700000000000,
            },
          });

      await notifier.createRecipe({'name': 'New Recipe'});

      expect(notifier.state.recipes.length, 2);
      expect(notifier.state.recipes[0].name, 'Existing');
      expect(notifier.state.recipes[1].name, 'New Recipe');
    });

    // ---------------------------------------------------------------------------
    // updateRecipe
    // ---------------------------------------------------------------------------
    test('updateRecipe sends PUT and returns updated recipe', () async {
      // First populate with a recipe to update
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'recipe-1',
                'trainer_id': 't1',
                'name': 'Original',
                'description': 'Original description',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchRecipes();
      expect(notifier.state.recipes[0].name, 'Original');

      // Update
      final updatedJson = <String, dynamic>{
        'data': {
          'id': 'recipe-1',
          'trainer_id': 't1',
          'name': 'Updated Recipe',
          'description': 'Updated description',
          'protein_g': 25.0,
          'carbs_g': 15.0,
          'fat_g': 8.0,
          'calories': 300,
          'created_at': 1700000000000,
          'updated_at': 1700000000001,
        },
      };

      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerRecipe('recipe-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => updatedJson);

      final updated = await notifier.updateRecipe('recipe-1', {
        'name': 'Updated Recipe',
        'protein_g': 25.0,
      });

      expect(updated.name, 'Updated Recipe');
      expect(updated.proteinG, 25.0);
      expect(notifier.state.recipes.length, 1);
      expect(notifier.state.recipes[0].name, 'Updated Recipe');
      expect(notifier.state.recipes[0].description, 'Updated description');
      expect(notifier.state.recipes[0].proteinG, 25.0);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.successMessage, 'Recipe updated');
    });

    test('updateRecipe sets isSaving before and after', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'name': 'Test',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchRecipes();

      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerRecipe('r1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'r1',
              'trainer_id': 't1',
              'name': 'Updated',
              'created_at': 1700000000000,
              'updated_at': 1700000000001,
            },
          });

      final future = notifier.updateRecipe('r1', {'name': 'Updated'});
      expect(notifier.state.isSaving, isTrue);
      await future;
      expect(notifier.state.isSaving, isFalse);
    });

    test('updateRecipe throws and sets error on DioException', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'name': 'Test',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchRecipes();

      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerRecipe('r1'),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerRecipe('r1')),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerRecipe('r1')),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Update failed'},
          },
        ),
      ));

      expect(
        () => notifier.updateRecipe('r1', {'name': 'Fail'}),
        throwsA(isA<DioException>()),
      );
      expect(notifier.state.error, 'Update failed');
    });

    // ---------------------------------------------------------------------------
    // deleteRecipe
    // ---------------------------------------------------------------------------
    test('deleteRecipe sends DELETE and removes recipe from list', () async {
      // First populate with recipes
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'name': 'Recipe One',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
              <String, dynamic>{
                'id': 'r2',
                'trainer_id': 't1',
                'name': 'Recipe Two',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchRecipes();
      expect(notifier.state.recipes.length, 2);

      when(() => mockApiClient.delete(ApiConstants.trainerRecipe('r1')))
          .thenAnswer((_) async => {});

      await notifier.deleteRecipe('r1');

      expect(notifier.state.recipes.length, 1);
      expect(notifier.state.recipes[0].id, 'r2');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.successMessage, 'Recipe deleted');
    });

    test('deleteRecipe sets error on DioException', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [
              <String, dynamic>{
                'id': 'r1',
                'trainer_id': 't1',
                'name': 'Recipe One',
                'created_at': 1700000000000,
                'updated_at': 1700000000000,
              },
            ],
          });

      await notifier.fetchRecipes();

      when(() => mockApiClient.delete(ApiConstants.trainerRecipe('r1')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerRecipe('r1')),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerRecipe('r1')),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Delete failed'},
          },
        ),
      ));

      await notifier.deleteRecipe('r1');

      expect(notifier.state.error, 'Delete failed');
      // Recipe should still be in the list
      expect(notifier.state.recipes.length, 1);
    });

    // ---------------------------------------------------------------------------
    // clearSuccessMessage
    // ---------------------------------------------------------------------------
    test('clearSuccessMessage clears the success message', () async {
      // Trigger a success message first via delete
      when(() => mockApiClient.delete(ApiConstants.trainerRecipe('nonexistent')))
          .thenAnswer((_) async => {});

      // We just need a state with a success message
      notifier = RecipeNotifier(apiClient: mockApiClient);

      // Manually set success message through state copy
      // by doing a delete on empty list (will succeed silently)
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'data': []});

      await notifier.fetchRecipes();

      when(() => mockApiClient.delete(ApiConstants.trainerRecipe('dummy')))
          .thenAnswer((_) async => {});

      await notifier.deleteRecipe('dummy');
      expect(notifier.state.successMessage, 'Recipe deleted');

      notifier.clearSuccessMessage();
      expect(notifier.state.successMessage, isNull);
    });
  });
}

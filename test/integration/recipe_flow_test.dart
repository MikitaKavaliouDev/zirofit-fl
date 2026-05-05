import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/recipe.dart';
import 'package:zirofit_fl/features/nutrition/providers/recipe_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _recipeJson({
  String id = 'recipe-1',
  String name = 'Test Recipe',
  String? description = 'A test recipe',
}) => {
      'id': id,
      'trainer_id': 'trainer-1',
      'name': name,
      'description': description,
      'instructions': 'Mix ingredients',
      'protein_g': 30.0,
      'carbs_g': 50.0,
      'fat_g': 10.0,
      'calories': 400,
      'difficulty': 'MEDIUM',
      'prep_time': 15,
      'cook_time': 30,
      'is_published': false,
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
      'deleted_at': null,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      recipesProvider.overrideWith(
        (ref) => RecipeNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('RecipeNotifier', () {
    test('initial state has empty recipes, not loading, no error, not saving', () {
      final state = container.read(recipesProvider);
      expect(state.recipes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSaving, isFalse);
      expect(state.successMessage, isNull);
    });

    test('fetchRecipes populates the recipe list', () async {
      final recipeListJson = [
        _recipeJson(id: 'r-1', name: 'Recipe One'),
        _recipeJson(id: 'r-2', name: 'Recipe Two'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': recipeListJson,
          });

      await container.read(recipesProvider.notifier).fetchRecipes();

      final state = container.read(recipesProvider);
      expect(state.recipes, hasLength(2));
      expect(state.recipes[0].id, 'r-1');
      expect(state.recipes[0].name, 'Recipe One');
      expect(state.recipes[1].name, 'Recipe Two');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchRecipes handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await container.read(recipesProvider.notifier).fetchRecipes();

      final state = container.read(recipesProvider);
      expect(state.recipes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchRecipes handles non-list data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{'recipes': <dynamic>[]},
          });

      await container.read(recipesProvider.notifier).fetchRecipes();

      final state = container.read(recipesProvider);
      expect(state.recipes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchRecipes sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
          )).thenThrow(Exception('API error'));

      await container.read(recipesProvider.notifier).fetchRecipes();

      final state = container.read(recipesProvider);
      expect(state.recipes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('createRecipe adds recipe to state and returns it', () async {
      final newRecipeJson = _recipeJson(
        id: 'r-new',
        name: 'New Recipe',
        description: 'Created via API',
      );

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': newRecipeJson,
          });

      final created = await container
          .read(recipesProvider.notifier)
          .createRecipe({'name': 'New Recipe', 'description': 'Created via API'});

      expect(created.id, 'r-new');
      expect(created.name, 'New Recipe');
      expect(created.description, 'Created via API');

      final state = container.read(recipesProvider);
      expect(state.recipes, hasLength(1));
      expect(state.recipes.first.id, 'r-new');
      expect(state.isSaving, isFalse);
      expect(state.successMessage, isNotNull);
    });

    test('createRecipe sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            body: any(named: 'body'),
          )).thenThrow(Exception('Create failed'));

      expect(
        () => container.read(recipesProvider.notifier).createRecipe({'name': 'Fail'}),
        throwsException,
      );

      final state = container.read(recipesProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNotNull);
    });

    test('updateRecipe updates recipe in state and returns it', () async {
      // Pre-populate a recipe
      final originalJson = _recipeJson(id: 'r-1', name: 'Original');
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [originalJson],
          });

      await container.read(recipesProvider.notifier).fetchRecipes();
      expect(container.read(recipesProvider).recipes, hasLength(1));

      // Mock the update
      final updatedJson = _recipeJson(id: 'r-1', name: 'Updated Name');
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerRecipe('r-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': updatedJson,
          });

      final updated = await container
          .read(recipesProvider.notifier)
          .updateRecipe('r-1', {'name': 'Updated Name'});

      expect(updated.name, 'Updated Name');
      expect(updated.id, 'r-1');

      final state = container.read(recipesProvider);
      expect(state.recipes, hasLength(1));
      expect(state.recipes.first.name, 'Updated Name');
      expect(state.isSaving, isFalse);
      expect(state.successMessage, isNotNull);
    });

    test('updateRecipe sets error on API failure', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerRecipe('r-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Update failed'));

      expect(
        () => container
            .read(recipesProvider.notifier)
            .updateRecipe('r-1', {'name': 'Fail'}),
        throwsException,
      );

      final state = container.read(recipesProvider);
      expect(state.isSaving, isFalse);
      expect(state.error, isNotNull);
    });

    test('deleteRecipe removes recipe from state', () async {
      // Pre-populate
      final recipeJson = _recipeJson(id: 'r-1');
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': [recipeJson],
          });

      await container.read(recipesProvider.notifier).fetchRecipes();
      expect(container.read(recipesProvider).recipes, hasLength(1));

      // Mock the delete
      when(() => mockApiClient.delete(
            ApiConstants.trainerRecipe('r-1'),
          )).thenAnswer((_) async => {});

      await container.read(recipesProvider.notifier).deleteRecipe('r-1');

      final state = container.read(recipesProvider);
      expect(state.recipes, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.successMessage, isNotNull);
    });

    test('deleteRecipe sets error on API failure', () async {
      when(() => mockApiClient.delete(
            ApiConstants.trainerRecipe('r-1'),
          )).thenThrow(Exception('Delete failed'));

      await container.read(recipesProvider.notifier).deleteRecipe('r-1');

      final state = container.read(recipesProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('clearSuccessMessage clears the success message', () async {
      // First populate to cause a success message
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerRecipes,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _recipeJson(),
          });

      await container
          .read(recipesProvider.notifier)
          .createRecipe({'name': 'Test'});
      expect(container.read(recipesProvider).successMessage, isNotNull);

      container.read(recipesProvider.notifier).clearSuccessMessage();

      expect(container.read(recipesProvider).successMessage, isNull);
    });
  });
}

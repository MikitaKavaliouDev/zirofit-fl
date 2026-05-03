import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/recipe.dart';
import 'package:zirofit_fl/features/nutrition/providers/recipe_provider.dart';
import 'package:zirofit_fl/features/nutrition/screens/recipe_detail_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeRecipeNotifier extends RecipeNotifier {
  final RecipesState _overriddenState;

  FakeRecipeNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  RecipesState get state => _overriddenState;

  @override
  Future<void> fetchRecipes() async {}

  @override
  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<Recipe> updateRecipe(String id, Map<String, dynamic> data) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteRecipe(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Recipe _createRecipe({
  String id = 'recipe-1',
  String name = 'Test Recipe',
  String? description = 'A test recipe',
  String? instructions = 'Mix ingredients',
  double? proteinG = 20.0,
  double? carbsG = 30.0,
  double? fatG = 10.0,
  int? calories = 300,
}) {
  return Recipe(
    id: id,
    trainerId: 'trainer-1',
    name: name,
    description: description,
    instructions: instructions,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
    calories: calories,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Widget buildTestApp(RecipesState state, {String recipeId = 'recipe-1'}) {
  return ProviderScope(
    overrides: [
      recipesProvider.overrideWith((ref) => FakeRecipeNotifier(state)),
    ],
    child: MaterialApp(
      home: RecipeDetailScreen(recipeId: recipeId),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading and recipe not yet loaded',
      (tester) async {
    await tester.pumpWidget(buildTestApp(
      const RecipesState(isLoading: true, recipes: []),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows recipe detail when loaded', (tester) async {
    final recipe = _createRecipe(
      name: 'Pasta Carbonara',
      description: 'Italian pasta dish',
      instructions: 'Cook pasta, add eggs, cheese, bacon.',
      proteinG: 25.0,
      carbsG: 40.0,
      fatG: 15.0,
      calories: 450,
    );

    await tester.pumpWidget(buildTestApp(
      RecipesState(recipes: [recipe], isLoading: false),
      recipeId: recipe.id,
    ));
    await tester.pump();

    // Recipe name appears in app bar and card; ensure at least one exists
    expect(find.text('Pasta Carbonara'), findsWidgets);
    // Description appears in card
    expect(
      find.descendant(
        of: find.byType(Card),
        matching: find.text('Italian pasta dish'),
      ),
      findsOneWidget,
    );
    // Instructions appear in card
    expect(
      find.descendant(
        of: find.byType(Card),
        matching: find.text('Cook pasta, add eggs, cheese, bacon.'),
      ),
      findsOneWidget,
    );
    // Macros appear in card
    expect(find.text('25.0g'), findsOneWidget);
    expect(find.text('40.0g'), findsOneWidget);
    expect(find.text('15.0g'), findsOneWidget);
    expect(find.text('450.0'), findsOneWidget);
  });

  testWidgets('shows recipe not found when recipe missing', (tester) async {
    await tester.pumpWidget(buildTestApp(
      const RecipesState(recipes: [], isLoading: false),
      recipeId: 'non-existent',
    ));
    await tester.pump();

    expect(find.text('Recipe not found'), findsOneWidget);
  });
}
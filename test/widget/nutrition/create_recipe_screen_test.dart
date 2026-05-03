import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/features/nutrition/screens/create_recipe_screen.dart';
import 'package:zirofit_fl/features/nutrition/providers/recipe_provider.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/data/models/recipe.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// Fake RecipeNotifier that overrides createRecipe to avoid real API calls.
class FakeRecipeNotifier extends RecipeNotifier {
  FakeRecipeNotifier({super.apiClient});

  @override
  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    // Return a dummy recipe
    return Recipe(
      id: 'new-recipe',
      trainerId: 'trainer-1',
      name: data['name'] ?? 'New Recipe',
      description: data['description'],
      instructions: data['instructions'],
      proteinG: data['protein_g']?.toDouble(),
      carbsG: data['carbs_g']?.toDouble(),
      fatG: data['fat_g']?.toDouble(),
      calories: data['calories'],
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

  group('CreateRecipeScreen', () {
    testWidgets('renders form fields and button', (tester) async {
      await tester.pumpApp(
        const CreateRecipeScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          recipesProvider.overrideWith(
            (ref) => FakeRecipeNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // App bar title and button both have "Create Recipe" text
      expect(find.text('Create Recipe'), findsNWidgets(2));

      // Recipe name field
      expect(find.widgetWithText(TextFormField, 'Recipe Name'), findsOneWidget);
      expect(find.text('e.g. Grilled Chicken Salad'), findsOneWidget);

      // Description field
      expect(find.widgetWithText(TextFormField, 'Description (optional)'), findsOneWidget);
      expect(find.text('Brief description of the recipe'), findsOneWidget);

      // Instructions field
      expect(find.widgetWithText(TextFormField, 'Instructions (optional)'), findsOneWidget);
      expect(find.text('Step-by-step instructions'), findsOneWidget);

      // Nutritional info section
      expect(find.text('Nutritional Info'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Protein (g)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Carbs (g)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Fat (g)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Calories'), findsOneWidget);

      // Submit button
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('validation shows error when recipe name is empty', (tester) async {
      await tester.pumpApp(
        const CreateRecipeScreen(),
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          recipesProvider.overrideWith(
            (ref) => FakeRecipeNotifier(apiClient: mockApiClient),
          ),
        ],
      );

      // Tap submit button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Expect validation error for recipe name
      expect(find.text('Please enter a recipe name'), findsOneWidget);
    });
  });
}

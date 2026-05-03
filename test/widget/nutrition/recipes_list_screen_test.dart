import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/recipe.dart';
import 'package:zirofit_fl/features/nutrition/providers/recipe_provider.dart';
import 'package:zirofit_fl/features/nutrition/screens/recipes_list_screen.dart';
import '../../helpers/test_setup.dart';

class FakeRecipesNotifier extends RecipeNotifier {
  RecipesState _state;
  FakeRecipesNotifier(this._state) : super(apiClient: ApiClient.instance) {
    super.state = _state;
  }

  @override
  RecipesState get state => _state;

  void emit(RecipesState s) {
    _state = s;
    super.state = s;
  }

  @override
  Future<void> fetchRecipes() async {}
}

Widget buildApp(RecipesState state) {
  return ProviderScope(
    overrides: [
      recipesProvider.overrideWith(
        (ref) => FakeRecipesNotifier(state),
      ),
    ],
    child: const MaterialApp(
      home: RecipesListScreen(),
    ),
  );
}

void main() {
  setUpAll(() => configureTestApiClient());

  group('RecipesListScreen', () {
    final now = DateTime.now();

    testWidgets('shows loading indicator when isLoading and recipes empty',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const RecipesState(isLoading: true)),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('shows error state with retry button', (tester) async {
      await tester.pumpWidget(
        buildApp(const RecipesState(error: 'Something went wrong')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows empty state when no recipes', (tester) async {
      await tester.pumpWidget(
        buildApp(const RecipesState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No recipes yet'), findsOneWidget);
      expect(
        find.textContaining('Create your first recipe'),
        findsOneWidget,
      );
    });

    testWidgets('shows list of recipes in data state', (tester) async {
      final recipes = [
        Recipe(
          id: '1',
          trainerId: 't1',
          name: 'Grilled Chicken Salad',
          description: 'A healthy and delicious salad',
          proteinG: 30.0,
          carbsG: 10.0,
          fatG: 5.0,
          calories: 350,
          createdAt: now,
          updatedAt: now,
        ),
        Recipe(
          id: '2',
          trainerId: 't1',
          name: 'Protein Smoothie',
          description: 'Quick post-workout drink',
          proteinG: 25.0,
          carbsG: 20.0,
          fatG: 2.0,
          calories: 200,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(RecipesState(recipes: recipes, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grilled Chicken Salad'), findsOneWidget);
      expect(find.text('Protein Smoothie'), findsOneWidget);
      expect(find.text('A healthy and delicious salad'), findsOneWidget);
      expect(find.text('Quick post-workout drink'), findsOneWidget);
    });

    testWidgets('shows FAB for creating recipes', (tester) async {
      await tester.pumpWidget(
        buildApp(const RecipesState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows recipes without description gracefully', (tester) async {
      final recipes = [
        Recipe(
          id: '3',
          trainerId: 't1',
          name: 'Minimal Recipe',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(RecipesState(recipes: recipes, isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal Recipe'), findsOneWidget);
      // ListTile should not have a subtitle since description is null
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(
        buildApp(const RecipesState(isLoading: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search recipes...'), findsOneWidget);
    });

    testWidgets('filters recipes by search query', (tester) async {
      final recipes = [
        Recipe(
          id: '1',
          trainerId: 't1',
          name: 'Grilled Chicken',
          description: 'Tasty chicken recipe',
          createdAt: now,
          updatedAt: now,
        ),
        Recipe(
          id: '2',
          trainerId: 't1',
          name: 'Vegan Salad',
          description: 'Plant-based salad',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(RecipesState(recipes: recipes, isLoading: false)),
      );
      await tester.pumpAndSettle();

      // Both recipes visible initially
      expect(find.text('Grilled Chicken'), findsOneWidget);
      expect(find.text('Vegan Salad'), findsOneWidget);

      // Type search query
      await tester.enterText(find.byType(TextField), 'chicken');
      await tester.pumpAndSettle();

      // Only matching recipe visible
      expect(find.text('Grilled Chicken'), findsOneWidget);
      expect(find.text('Vegan Salad'), findsNothing);
    });

    testWidgets('shows search empty state when no matches', (tester) async {
      final recipes = [
        Recipe(
          id: '1',
          trainerId: 't1',
          name: 'Grilled Chicken',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        buildApp(RecipesState(recipes: recipes, isLoading: false)),
      );
      await tester.pumpAndSettle();

      // Type non-matching search
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No recipes match your search'), findsOneWidget);
      expect(find.text('Try a different search term.'), findsOneWidget);
    });
  });
}

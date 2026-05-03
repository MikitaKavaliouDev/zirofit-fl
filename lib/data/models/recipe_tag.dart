class RecipeTag {
  final String id;
  final String recipeId;
  final String name;

  const RecipeTag({
    required this.id,
    required this.recipeId,
    required this.name,
  });

  factory RecipeTag.fromJson(Map<String, dynamic> json) =>
      RecipeTag(
        id: json['id'] as String,
        recipeId: json['recipe_id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipe_id': recipeId,
        'name': name,
      };

  @override
  String toString() =>
      'RecipeTag(id: $id, recipeId: $recipeId, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeTag &&
          id == other.id &&
          recipeId == other.recipeId &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, recipeId, name);
}

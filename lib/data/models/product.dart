class Product {
  final String id;
  final String recipeId;
  final String name;
  final String? brand;
  final String? amount;
  final bool isRecommended;

  const Product({
    required this.id,
    required this.recipeId,
    required this.name,
    this.brand,
    this.amount,
    this.isRecommended = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      Product(
        id: json['id'] as String,
        recipeId: json['recipe_id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String?,
        amount: json['amount'] as String?,
        isRecommended:
            (json['is_recommended'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipe_id': recipeId,
        'name': name,
        'brand': brand,
        'amount': amount,
        'is_recommended': isRecommended,
      };

  @override
  String toString() =>
      'Product(id: $id, recipeId: $recipeId, name: $name, '
      'brand: $brand, amount: $amount, '
      'isRecommended: $isRecommended)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          id == other.id &&
          recipeId == other.recipeId &&
          name == other.name &&
          brand == other.brand &&
          amount == other.amount &&
          isRecommended == other.isRecommended;

  @override
  int get hashCode => Object.hash(
        id,
        recipeId,
        name,
        brand,
        amount,
        isRecommended,
      );
}

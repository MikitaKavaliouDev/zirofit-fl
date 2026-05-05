/// Standard Olympic plate weights in kg available for calculation.
const List<double> kStandardPlates = [25, 20, 15, 10, 5, 2.5, 1.25];

/// Represents a set of plates of the same weight on one side of the bar.
class PlateSet {
  final double weight;
  final int count;

  const PlateSet({required this.weight, required this.count});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlateSet &&
          weight == other.weight &&
          count == other.count;

  @override
  int get hashCode => Object.hash(weight, count);

  @override
  String toString() => 'PlateSet(weight: $weight, count: $count)';
}

/// Represents a complete plate calculation for a barbell lift.
class PlateCalculation {
  final double totalWeight;
  final double barWeight;
  final List<PlateSet> platesPerSide;

  const PlateCalculation({
    required this.totalWeight,
    this.barWeight = 20.0,
    required this.platesPerSide,
  });

  /// Weight needed on each side of the bar.
  double get weightPerSide => (totalWeight - barWeight) / 2;

  /// Formatted string, e.g. "100 kg".
  String get formatted => '${totalWeight.toStringAsFixed(0)} kg';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlateCalculation &&
          totalWeight == other.totalWeight &&
          barWeight == other.barWeight &&
          _listEquals(platesPerSide, other.platesPerSide);

  @override
  int get hashCode => Object.hash(totalWeight, barWeight, platesPerSide);

  @override
  String toString() =>
      'PlateCalculation(totalWeight: $totalWeight, barWeight: $barWeight, '
      'platesPerSide: $platesPerSide)';

  static bool _listEquals(List<PlateSet> a, List<PlateSet> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Calculates the plates needed on each side of the bar to reach [targetWeight].
///
/// Uses a greedy algorithm with standard Olympic plates:
/// 25, 20, 15, 10, 5, 2.5, 1.25 kg.
///
/// Returns a list of [PlateSet] sorted heaviest to lightest. Returns an empty
/// list if [targetWeight] is less than [barWeight].
List<PlateSet> calculatePlates(double targetWeight, {double barWeight = 20.0}) {
  if (targetWeight < barWeight) return [];

  final weightPerSide = (targetWeight - barWeight) / 2;
  if (weightPerSide <= 0) return [];

  var remaining = weightPerSide;
  final result = <PlateSet>[];

  for (final plateWeight in kStandardPlates) {
    if (remaining < plateWeight) continue;

    final count = (remaining / plateWeight).floor();
    if (count > 0) {
      result.add(PlateSet(weight: plateWeight, count: count));
      remaining -= count * plateWeight;
      // Round to avoid floating-point drift
      remaining = (remaining * 100).roundToDouble() / 100;
    }
  }

  return result;
}

/// Enum representing the exercise category in a template step.
///
/// Wire values: `"MAIN"`, `"ASSISTANCE"`, `"ACCESSORY"`, `"ADDITION"`, `"WARMUP"`
enum ExerciseCategory {
  main,
  assistance,
  accessory,
  addition,
  warmup;

  factory ExerciseCategory.fromJson(String value) =>
      ExerciseCategory.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
      );

  String toJson() => name.toUpperCase();
}

/// Progress summary for the active program.
///
/// Returned inside the `GET /client/program/active` response.
class ActiveProgramProgress {
  final int completedCount;
  final int totalCount;
  final double progressPercentage;
  final String? nextTemplateId;

  const ActiveProgramProgress({
    required this.completedCount,
    required this.totalCount,
    this.progressPercentage = 0,
    this.nextTemplateId,
  });

  factory ActiveProgramProgress.fromJson(Map<String, dynamic> json) =>
      ActiveProgramProgress(
        completedCount: (json['completedCount'] as int?) ?? 0,
        totalCount: (json['totalCount'] as int?) ?? 0,
        progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
        nextTemplateId: json['nextTemplateId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'completedCount': completedCount,
    'totalCount': totalCount,
    'progressPercentage': progressPercentage,
    'nextTemplateId': nextTemplateId,
  };

  @override
  String toString() =>
      'ActiveProgramProgress(completedCount: $completedCount, '
      'totalCount: $totalCount, progressPercentage: $progressPercentage, '
      'nextTemplateId: $nextTemplateId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveProgramProgress &&
          completedCount == other.completedCount &&
          totalCount == other.totalCount &&
          progressPercentage == other.progressPercentage &&
          nextTemplateId == other.nextTemplateId;

  @override
  int get hashCode => Object.hash(
    completedCount,
    totalCount,
    progressPercentage,
    nextTemplateId,
  );
}

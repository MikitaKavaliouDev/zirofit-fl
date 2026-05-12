import 'package:flutter/material.dart';

/// Data model for volume tracking over time (line & bar charts).
@immutable
class VolumeData {
  final DateTime date;
  final double volume;

  const VolumeData({required this.date, required this.volume});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeData &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          volume == other.volume;

  @override
  int get hashCode => date.hashCode ^ volume.hashCode;
}

/// Date range options controlling bar chart x-axis granularity.
enum DateRange {
  last7Days,
  last30Days,
  threeMonths,
}

/// Data model for muscle group distribution (donut chart).
@immutable
class MuscleDistribution {
  final String group;
  final double value;
  final Color color;

  const MuscleDistribution({
    required this.group,
    required this.value,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuscleDistribution &&
          runtimeType == other.runtimeType &&
          group == other.group &&
          value == other.value &&
          color == other.color;

  @override
  int get hashCode => group.hashCode ^ value.hashCode ^ color.hashCode;
}

import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/event.dart';

/// Shared test fixtures for explore section widget tests.
///
/// Usage:
/// ```dart
/// final trainers = FakeExploreData.trainers;
/// final events = FakeExploreData.events;
/// final categories = FakeExploreData.categories;
/// ```
class FakeExploreData {
  FakeExploreData._();

  /// Sample trainers for testing the explore sections.
  static final List<Profile> trainers = [
    Profile(
      id: 't1',
      userId: 'u1',
      aboutMe: 'Alice Johnson',
      specialties: ['Yoga', 'Pilates'],
      averageRating: 4.8,
      location: 'San Francisco, CA',
      latitude: 37.7749,
      longitude: -122.4194,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    Profile(
      id: 't2',
      userId: 'u2',
      aboutMe: 'Bob Smith',
      specialties: ['Weight Training', 'HIIT'],
      averageRating: 4.5,
      location: 'Los Angeles, CA',
      latitude: 34.0522,
      longitude: -118.2437,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    Profile(
      id: 't3',
      userId: 'u3',
      aboutMe: 'Carol Williams',
      specialties: ['Running', 'CrossFit'],
      averageRating: 4.9,
      location: 'San Diego, CA',
      latitude: 32.7157,
      longitude: -117.1611,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  /// Sample featured trainers (top-rated subset).
  static List<Profile> get featuredTrainers => trainers;

  /// Sample nearby trainers (first 2).
  static List<Profile> get nearbyTrainers => trainers.take(2).toList();

  /// Sample events for testing event sections.
  static final List<Event> events = [
    Event(
      id: 'e1',
      trainerId: 't1',
      title: 'Morning Yoga Flow',
      description: 'Start your day with energizing yoga',
      startTime: DateTime.now().add(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
      category: 'Yoga',
      city: 'San Francisco, CA',
      latitude: 37.7749,
      longitude: -122.4194,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    Event(
      id: 'e2',
      trainerId: 't2',
      title: 'HIIT Blast',
      description: 'High intensity interval training',
      startTime: DateTime.now().add(const Duration(days: 2)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 1)),
      category: 'HIIT',
      city: 'Los Angeles, CA',
      latitude: 34.0522,
      longitude: -118.2437,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  /// Sample featured events.
  static List<Event> get featuredEvents => events;

  /// Sample upcoming events grouped by date.
  static Map<DateTime, List<Event>> get upcomingEventsByDate {
    final now = DateTime.now();
    return {
      DateTime(now.year, now.month, now.day + 1): [events[0]],
      DateTime(now.year, now.month, now.day + 2): [events[1]],
    };
  }

  /// Sample specialty categories.
  static const List<String> categories = [
    'Yoga',
    'Pilates',
    'Weight Training',
    'HIIT',
    'Running',
    'CrossFit',
    'Spin',
    'Boxing',
  ];

  /// Sample cities for city picker.
  static const List<String> cities = [
    'San Francisco, CA',
    'Los Angeles, CA',
    'San Diego, CA',
    'New York, NY',
    'Chicago, IL',
  ];
}
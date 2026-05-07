import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/services/deep_link_service.dart';

void main() {
  group('DeepLinkService.parse', () {
    // ---------------------------------------------------------------------------
    // Auth callback
    // ---------------------------------------------------------------------------
    test('parses auth callback URL with access token', () {
      const url = 'zirofitapp://auth/callback?access_token=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.authCallback);
      expect(route.accessToken, 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ');
      expect(route.params['access_token'], 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ');
    });

    test('parses auth callback URL with minimal token', () {
      const url = 'zirofitapp://auth/callback?access_token=abc123';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.authCallback);
      expect(route.accessToken, 'abc123');
    });

    test('returns null for auth callback without access_token', () {
      const url = 'zirofitapp://auth/callback';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for auth callback with empty access_token', () {
      const url = 'zirofitapp://auth/callback?access_token=';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for auth callback with missing token param', () {
      const url = 'zirofitapp://auth/callback?code=abc';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    // ---------------------------------------------------------------------------
    // Event detail
    // ---------------------------------------------------------------------------
    test('parses event URL with id', () {
      const url = 'zirofitapp://events/evt_001';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.eventDetail);
      expect(route.eventId, 'evt_001');
    });

    test('parses event URL with UUID id', () {
      const url = 'zirofitapp://events/550e8400-e29b-41d4-a716-446655440000';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.eventDetail);
      expect(route.eventId, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('parses event URL with numeric id', () {
      const url = 'zirofitapp://events/42';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.eventDetail);
      expect(route.eventId, '42');
    });

    test('returns null for event URL with empty id', () {
      const url = 'zirofitapp://events/';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    // ---------------------------------------------------------------------------
    // Trainer profile
    // ---------------------------------------------------------------------------
    test('parses trainer URL with id', () {
      const url = 'zirofitapp://trainer/tr_123';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.trainerProfile);
      expect(route.trainerId, 'tr_123');
    });

    test('parses trainer URL with UUID id', () {
      const url = 'zirofitapp://trainer/f47ac10b-58cc-4372-a567-0e02b2c3d479';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.trainerProfile);
      expect(route.trainerId, 'f47ac10b-58cc-4372-a567-0e02b2c3d479');
    });

    test('returns null for trainer URL with empty id', () {
      const url = 'zirofitapp://trainer/';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    // ---------------------------------------------------------------------------
    // Workout
    // ---------------------------------------------------------------------------
    test('parses workout URL with id', () {
      const url = 'zirofitapp://workout/wo_456';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.workout);
      expect(route.workoutId, 'wo_456');
    });

    test('parses workout URL with numeric id', () {
      const url = 'zirofitapp://workout/99';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.workout);
      expect(route.workoutId, '99');
    });

    test('returns null for workout URL with empty id', () {
      const url = 'zirofitapp://workout/';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    // ---------------------------------------------------------------------------
    // Unknown / malformed URLs
    // ---------------------------------------------------------------------------
    test('returns null for unknown deep link path', () {
      const url = 'zirofitapp://unknown/path';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for unknown scheme', () {
      const url = 'https://example.com/path';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for completely unrelated URL', () {
      const url = 'com.example.app://open?foo=bar';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for empty string', () {
      const url = '';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for malformed URL', () {
      const url = 'not a url at all !!!';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for URL with only scheme', () {
      const url = 'zirofitapp://';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    test('returns null for URL with scheme but no path', () {
      const url = 'zirofitapp://?foo=bar';
      final route = DeepLinkService.parse(url);

      expect(route, isNull);
    });

    // ---------------------------------------------------------------------------
    // Edge cases
    // ---------------------------------------------------------------------------
    test('parses URL with extra query parameters', () {
      const url = 'zirofitapp://events/evt_001?source=email&campaign=onboarding';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.eventDetail);
      expect(route.eventId, 'evt_001');
    });

    test('parses auth callback with extra query parameters', () {
      const url = 'zirofitapp://auth/callback?access_token=abc&refresh_token=def&expires=3600';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.authCallback);
      expect(route.accessToken, 'abc');
      // The params map should only contain the parsed access_token
      expect(route.params['refresh_token'], isNull);
    });

    test('parses URL with trailing slash in path', () {
      const url = 'zirofitapp://workout/wo_789/';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.workout);
      expect(route.workoutId, 'wo_789');
    });

    test('parses event URL with extra path segments after id', () {
      const url = 'zirofitapp://events/evt_001/details';
      final route = DeepLinkService.parse(url);

      // Should still match since segments[0] == 'events' and segments[1] is non-empty
      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.eventDetail);
      expect(route.eventId, 'evt_001');
    });

    test('parses URL with special characters in id', () {
      const url = 'zirofitapp://trainer/trainer_123_abc';
      final route = DeepLinkService.parse(url);

      expect(route, isNotNull);
      expect(route!.type, DeepLinkRouteType.trainerProfile);
      expect(route.trainerId, 'trainer_123_abc');
    });

    // ---------------------------------------------------------------------------
    // Constructor and factory
    // ---------------------------------------------------------------------------
    test('DeepLinkService singleton returns same instance', () {
      final service1 = DeepLinkService();
      final service2 = DeepLinkService();

      expect(service1, same(service2));
    });

    test('DeepLinkRoute equality works', () {
      final route1 = DeepLinkService.parse('zirofitapp://events/abc');
      final route2 = DeepLinkService.parse('zirofitapp://events/abc');
      final route3 = DeepLinkService.parse('zirofitapp://events/def');

      expect(route1, equals(route2));
      expect(route1, isNot(equals(route3)));
    });

    test('DeepLinkRoute toString includes type and params', () {
      const url = 'zirofitapp://events/evt_001';
      final route = DeepLinkService.parse(url);

      expect(route.toString(), contains('DeepLinkRoute'));
      expect(route.toString(), contains('eventDetail'));
      expect(route.toString(), contains('evt_001'));
    });
  });
}

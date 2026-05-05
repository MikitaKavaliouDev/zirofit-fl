import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _testTimestamp = 1700000000000;

Map<String, dynamic> _statsJson() => {
      'total_users': 150,
      'active_trainers': 25,
      'total_bookings': 1200,
      'revenue': 45000.0,
    };

Map<String, dynamic> _eventJson({
  String id = 'event-1',
  String status = 'PENDING',
}) => {
      'id': id,
      'trainer_id': 'trainer-1',
      'title': 'Test Event',
      'description': 'An event',
      'start_time': _testTimestamp,
      'end_time': _testTimestamp + 7200000,
      'location_name': 'Gym',
      'address': '123 Main St',
      'city': 'Warsaw',
      'latitude': 52.23,
      'longitude': 21.01,
      'price': 50.0,
      'currency': 'PLN',
      'capacity': 20,
      'enrolled_count': 5,
      'category': 'WORKSHOP',
      'image_url': null,
      'is_promoted': false,
      'status': status,
      'rejection_reason': null,
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
    };

Map<String, dynamic> _blogPostJson({
  String id = 'post-1',
  String title = 'Test Post',
}) => {
      'id': id,
      'title': title,
      'slug': 'test-post',
      'content': 'Post content',
      'excerpt': 'Short excerpt',
      'cover_image': null,
      'published': false,
      'author_id': 'admin-1',
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
      'published_at': null,
    };

Map<String, dynamic> _ticketJson({
  String id = 'ticket-1',
  String status = 'OPEN',
}) => {
      'id': id,
      'user_id': 'user-1',
      'category': 'BUG_REPORT',
      'message': 'Bug report',
      'app_version': '1.0.0',
      'os_version': 'iOS 17',
      'status': status,
      'created_at': _testTimestamp,
      'updated_at': _testTimestamp,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      adminProvider.overrideWith(
        (ref) => AdminNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('AdminNotifier', () {
    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------

    test('initial state has empty lists, no stats, not loading, no error', () {
      final state = container.read(adminProvider);
      expect(state.stats, isNull);
      expect(state.pendingEvents, isEmpty);
      expect(state.blogPosts, isEmpty);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    // -------------------------------------------------------------------------
    // Stats
    // -------------------------------------------------------------------------

    test('fetchStats populates stats', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminStats,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': _statsJson(),
          });

      await container.read(adminProvider.notifier).fetchStats();

      final state = container.read(adminProvider);
      expect(state.stats, isNotNull);
      expect(state.stats!['total_users'], 150);
      expect(state.stats!['revenue'], 45000.0);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchStats handles null data by falling back to result map', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminStats,
          )).thenAnswer((_) async => _statsJson()); // no 'data' wrapper

      await container.read(adminProvider.notifier).fetchStats();

      final state = container.read(adminProvider);
      expect(state.stats, isNotNull);
      expect(state.stats!['total_users'], 150);
    });

    test('fetchStats sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminStats,
          )).thenThrow(Exception('Stats error'));

      await container.read(adminProvider.notifier).fetchStats();

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    test('fetchPendingEvents populates the events list', () async {
      final eventListJson = [
        _eventJson(id: 'e-1', status: 'PENDING'),
        _eventJson(id: 'e-2', status: 'PENDING'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminEvents,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': eventListJson,
          });

      await container.read(adminProvider.notifier).fetchPendingEvents();

      final state = container.read(adminProvider);
      expect(state.pendingEvents, hasLength(2));
      expect(state.pendingEvents[0].id, 'e-1');
      expect(state.pendingEvents[0].status.name, 'pending');
      expect(state.isLoading, isFalse);
    });

    test('fetchPendingEvents handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminEvents,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await container.read(adminProvider.notifier).fetchPendingEvents();

      final state = container.read(adminProvider);
      expect(state.pendingEvents, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchPendingEvents handles null data gracefully', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminEvents,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': null,
          });

      await container.read(adminProvider.notifier).fetchPendingEvents();

      final state = container.read(adminProvider);
      expect(state.pendingEvents, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchPendingEvents sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminEvents,
          )).thenThrow(Exception('Events error'));

      await container.read(adminProvider.notifier).fetchPendingEvents();

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('moderateEvent removes event from pending list on success', () async {
      // Pre-populate events
      final eventListJson = [
        _eventJson(id: 'e-1'),
        _eventJson(id: 'e-2'),
      ];
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminEvents,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': eventListJson,
          });

      await container.read(adminProvider.notifier).fetchPendingEvents();
      expect(container.read(adminProvider).pendingEvents, hasLength(2));

      // Moderate one event
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiConstants.adminEvent('e-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await container.read(adminProvider.notifier).moderateEvent('e-1', 'approve');

      final state = container.read(adminProvider);
      expect(state.pendingEvents, hasLength(1));
      expect(state.pendingEvents.first.id, 'e-2');
      expect(state.isLoading, isFalse);
    });

    test('moderateEvent sets error on API failure', () async {
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiConstants.adminEvent('e-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Moderate failed'));

      await container.read(adminProvider.notifier).moderateEvent('e-1', 'approve');

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Blog Posts
    // -------------------------------------------------------------------------

    test('fetchBlogPosts populates the blog posts list', () async {
      final postListJson = [
        _blogPostJson(id: 'p-1', title: 'Post One'),
        _blogPostJson(id: 'p-2', title: 'Post Two'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminBlog,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': postListJson,
          });

      await container.read(adminProvider.notifier).fetchBlogPosts();

      final state = container.read(adminProvider);
      expect(state.blogPosts, hasLength(2));
      expect(state.blogPosts[0].id, 'p-1');
      expect(state.blogPosts[0].title, 'Post One');
      expect(state.blogPosts[1].title, 'Post Two');
      expect(state.isLoading, isFalse);
    });

    test('fetchBlogPosts handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminBlog,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await container.read(adminProvider.notifier).fetchBlogPosts();

      final state = container.read(adminProvider);
      expect(state.blogPosts, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchBlogPosts sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminBlog,
          )).thenThrow(Exception('Blog error'));

      await container.read(adminProvider.notifier).fetchBlogPosts();

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('createBlogPost adds post to state and parses response', () async {
      final newPostJson = _blogPostJson(id: 'p-new', title: 'New Post');

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.adminBlog,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': newPostJson,
          });

      await container
          .read(adminProvider.notifier)
          .createBlogPost({'title': 'New Post', 'content': 'Content'});

      final state = container.read(adminProvider);
      expect(state.blogPosts, hasLength(1));
      expect(state.blogPosts.first.id, 'p-new');
      expect(state.blogPosts.first.title, 'New Post');
      expect(state.isLoading, isFalse);
    });

    test('createBlogPost sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.adminBlog,
            body: any(named: 'body'),
          )).thenThrow(Exception('Create post failed'));

      await container
          .read(adminProvider.notifier)
          .createBlogPost({'title': 'Fail'});

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('deleteBlogPost removes post from state', () async {
      // Pre-populate
      final postListJson = [_blogPostJson(id: 'p-1')];
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminBlog,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': postListJson,
          });

      await container.read(adminProvider.notifier).fetchBlogPosts();
      expect(container.read(adminProvider).blogPosts, hasLength(1));

      // Delete
      when(() => mockApiClient.delete(
            ApiConstants.adminBlogPost('p-1'),
          )).thenAnswer((_) async => {});

      await container.read(adminProvider.notifier).deleteBlogPost('p-1');

      final state = container.read(adminProvider);
      expect(state.blogPosts, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('deleteBlogPost sets error on API failure', () async {
      when(() => mockApiClient.delete(
            ApiConstants.adminBlogPost('p-1'),
          )).thenThrow(Exception('Delete failed'));

      await container.read(adminProvider.notifier).deleteBlogPost('p-1');

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Tickets
    // -------------------------------------------------------------------------

    test('fetchTickets populates the tickets list', () async {
      final ticketListJson = [
        _ticketJson(id: 't-1', status: 'OPEN'),
        _ticketJson(id: 't-2', status: 'RESOLVED'),
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminTickets,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': ticketListJson,
          });

      await container.read(adminProvider.notifier).fetchTickets();

      final state = container.read(adminProvider);
      expect(state.tickets, hasLength(2));
      expect(state.tickets[0].id, 't-1');
      expect(state.tickets[0].status, 'OPEN');
      expect(state.tickets[1].status, 'RESOLVED');
      expect(state.isLoading, isFalse);
    });

    test('fetchTickets handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminTickets,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await container.read(adminProvider.notifier).fetchTickets();

      final state = container.read(adminProvider);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, isFalse);
    });

    test('fetchTickets sets error on API failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminTickets,
          )).thenThrow(Exception('Tickets error'));

      await container.read(adminProvider.notifier).fetchTickets();

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('updateTicketStatus updates the ticket status in state', () async {
      // Pre-populate
      final ticketListJson = [_ticketJson(id: 't-1', status: 'OPEN')];
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminTickets,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': ticketListJson,
          });

      await container.read(adminProvider.notifier).fetchTickets();
      expect(
        container.read(adminProvider).tickets.first.status,
        'OPEN',
      );

      // Update status
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiConstants.adminTicket('t-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await container
          .read(adminProvider.notifier)
          .updateTicketStatus('t-1', 'RESOLVED');

      final state = container.read(adminProvider);
      expect(state.tickets, hasLength(1));
      expect(state.tickets.first.status, 'RESOLVED');
      expect(state.isLoading, isFalse);
    });

    test('updateTicketStatus sets error on API failure', () async {
      when(() => mockApiClient.patch<Map<String, dynamic>>(
            ApiConstants.adminTicket('t-1'),
            body: any(named: 'body'),
          )).thenThrow(Exception('Update status failed'));

      await container
          .read(adminProvider.notifier)
          .updateTicketStatus('t-1', 'RESOLVED');

      final state = container.read(adminProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Clear error
    // -------------------------------------------------------------------------

    test('clearError clears the error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.adminStats,
          )).thenThrow(Exception('Some error'));

      await container.read(adminProvider.notifier).fetchStats();
      expect(container.read(adminProvider).error, isNotNull);

      container.read(adminProvider.notifier).clearError();

      expect(container.read(adminProvider).error, isNull);
    });
  });
}

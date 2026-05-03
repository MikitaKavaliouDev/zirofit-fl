import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _statsJson() => {
      'data': {
        'totalUsers': 100,
        'totalTrainers': 15,
        'totalClients': 85,
        'totalEvents': 25,
        'pendingEvents': 3,
        'totalBlogPosts': 10,
        'openTickets': 5,
      },
    };

Map<String, dynamic> _eventJson({
  String id = 'evt-1',
  String title = 'Test Event',
}) =>
    {
      'id': id,
      'trainer_id': 'trainer-1',
      'title': title,
      'start_time': 1700000000000,
      'end_time': 1700003600000,
      'price': 0,
      'capacity': 20,
      'enrolled_count': 0,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
    };

Map<String, dynamic> _blogPostJson({
  String id = 'post-1',
  String title = 'Test Post',
}) =>
    {
      'id': id,
      'title': title,
      'slug': 'test-post',
      'content': 'Full content',
      'published': true,
      'author_id': 'author-1',
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'published_at': 1700000000000,
    };

Map<String, dynamic> _ticketJson({
  String id = 'ticket-1',
  String status = 'OPEN',
}) =>
    {
      'id': id,
      'user_id': 'user-1',
      'category': 'GENERAL_SUPPORT',
      'message': 'Need help',
      'status': status,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
    };

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('AdminNotifier', () {
    test('initial state is correct', () {
      final state = container.read(adminProvider);
      expect(state.stats, isNull);
      expect(state.pendingEvents, isEmpty);
      expect(state.blogPosts, isEmpty);
      expect(state.tickets, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    group('fetchStats', () {
      test('populates stats on success', () async {
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminStats,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => _statsJson());

        await container.read(adminProvider.notifier).fetchStats();

        final state = container.read(adminProvider);
        expect(state.stats, isNotNull);
        expect(state.stats!['totalUsers'], 100);
        expect(state.stats!['totalTrainers'], 15);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('sets error on failure', () async {
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminStats,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminStats),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.adminStats),
            statusCode: 500,
            data: <String, dynamic>{'message': 'Server error'},
          ),
        ));

        await container.read(adminProvider.notifier).fetchStats();

        final state = container.read(adminProvider);
        expect(state.stats, isNull);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('fetchPendingEvents', () {
      test('populates pending events on success', () async {
        final events = [_eventJson(id: 'evt-1'), _eventJson(id: 'evt-2', title: 'Second Event')];

        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminEvents,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {'data': events});

        await container.read(adminProvider.notifier).fetchPendingEvents();

        final state = container.read(adminProvider);
        expect(state.pendingEvents, hasLength(2));
        expect(state.pendingEvents[0].id, 'evt-1');
        expect(state.pendingEvents[1].title, 'Second Event');
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('sets error on failure', () async {
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminEvents,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminEvents),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.adminEvents),
            statusCode: 500,
            data: <String, dynamic>{'message': 'Server error'},
          ),
        ));

        await container.read(adminProvider.notifier).fetchPendingEvents();

        final state = container.read(adminProvider);
        expect(state.pendingEvents, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('moderateEvent', () {
      test('removes event from pending on success', () async {
        // First load events
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminEvents,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {
              'data': [_eventJson()],
            });

        await container.read(adminProvider.notifier).fetchPendingEvents();
        expect(container.read(adminProvider).pendingEvents, hasLength(1));

        // Stub moderate PATCH
        when<Future<Map<String, dynamic>>>(() => mockApiClient.patch(
              ApiConstants.adminEvent('evt-1'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => {'data': {'message': 'Approved'}});

        // Act
        await container.read(adminProvider.notifier).moderateEvent('evt-1', 'approve');

        // Assert
        final state = container.read(adminProvider);
        expect(state.pendingEvents, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('sets error on failure', () async {
        // First load events
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminEvents,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {
              'data': [_eventJson()],
            });

        await container.read(adminProvider.notifier).fetchPendingEvents();
        expect(container.read(adminProvider).pendingEvents, hasLength(1));

        // Stub moderate to fail
        when<Future<Map<String, dynamic>>>(() => mockApiClient.patch(
              ApiConstants.adminEvent('evt-1'),
              body: any(named: 'body'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminEvent('evt-1')),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.adminEvent('evt-1')),
            statusCode: 400,
            data: <String, dynamic>{'message': 'Cannot moderate'},
          ),
        ));

        // Act
        await container.read(adminProvider.notifier).moderateEvent('evt-1', 'reject');

        // Assert
        final state = container.read(adminProvider);
        expect(state.pendingEvents, hasLength(1)); // Not removed
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('fetchBlogPosts', () {
      test('populates blog posts on success', () async {
        final posts = [_blogPostJson(), _blogPostJson(id: 'post-2', title: 'Second Post')];

        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminBlog,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {'data': posts});

        await container.read(adminProvider.notifier).fetchBlogPosts();

        final state = container.read(adminProvider);
        expect(state.blogPosts, hasLength(2));
        expect(state.blogPosts[0].id, 'post-1');
        expect(state.blogPosts[1].title, 'Second Post');
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('sets error on failure', () async {
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminBlog,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminBlog),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.adminBlog),
            statusCode: 500,
            data: <String, dynamic>{'message': 'Server error'},
          ),
        ));

        await container.read(adminProvider.notifier).fetchBlogPosts();

        final state = container.read(adminProvider);
        expect(state.blogPosts, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('createBlogPost', () {
      test('adds post to list on success', () async {
        final newPostData = {
          'title': 'New Post',
          'slug': 'new-post',
          'content': 'Content',
          'published': true,
        };

        when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
              ApiConstants.adminBlog,
              body: any(named: 'body'),
            )).thenAnswer((_) async => {
              'data': _blogPostJson(id: 'post-new', title: 'New Post'),
            });

        await container
            .read(adminProvider.notifier)
            .createBlogPost(newPostData);

        final state = container.read(adminProvider);
        expect(state.blogPosts, hasLength(1));
        expect(state.blogPosts[0].title, 'New Post');
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('sets error on failure', () async {
        when<Future<Map<String, dynamic>>>(() => mockApiClient.post(
              ApiConstants.adminBlog,
              body: any(named: 'body'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminBlog),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.adminBlog),
            statusCode: 500,
            data: <String, dynamic>{'message': 'Server error'},
          ),
        ));

        await container
            .read(adminProvider.notifier)
            .createBlogPost({'title': 'Fail'});

        final state = container.read(adminProvider);
        expect(state.blogPosts, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('deleteBlogPost', () {
      test('removes post from list on success', () async {
        // First load posts
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminBlog,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {
              'data': [_blogPostJson(), _blogPostJson(id: 'post-2')],
            });

        await container.read(adminProvider.notifier).fetchBlogPosts();
        expect(container.read(adminProvider).blogPosts, hasLength(2));

        // Stub delete
        when(() => mockApiClient.delete(ApiConstants.adminBlogPost('post-1')))
            .thenAnswer((_) async => {});

        // Act
        await container.read(adminProvider.notifier).deleteBlogPost('post-1');

        // Assert
        final state = container.read(adminProvider);
        expect(state.blogPosts, hasLength(1));
        expect(state.blogPosts[0].id, 'post-2');
        expect(state.isLoading, false);
      });

      test('sets error on failure', () async {
        // First load posts
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminBlog,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {
              'data': [_blogPostJson()],
            });

        await container.read(adminProvider.notifier).fetchBlogPosts();
        expect(container.read(adminProvider).blogPosts, hasLength(1));

        // Stub delete to fail
        when(() => mockApiClient.delete(ApiConstants.adminBlogPost('post-1')))
            .thenThrow(DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.adminBlogPost('post-1')),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions:
                RequestOptions(path: ApiConstants.adminBlogPost('post-1')),
            statusCode: 500,
            data: <String, dynamic>{'message': 'Delete failed'},
          ),
        ));

        // Act
        await container.read(adminProvider.notifier).deleteBlogPost('post-1');

        // Assert
        final state = container.read(adminProvider);
        expect(state.blogPosts, hasLength(1)); // Not removed
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('fetchTickets', () {
      test('populates tickets on success', () async {
        final tickets = [_ticketJson(), _ticketJson(id: 'ticket-2', status: 'IN_PROGRESS')];

        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminTickets,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {'data': tickets});

        await container.read(adminProvider.notifier).fetchTickets();

        final state = container.read(adminProvider);
        expect(state.tickets, hasLength(2));
        expect(state.tickets[0].id, 'ticket-1');
        expect(state.tickets[1].status, 'IN_PROGRESS');
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('sets error on failure', () async {
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminTickets,
              queryParams: any(named: 'queryParams'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.adminTickets),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.adminTickets),
            statusCode: 500,
            data: <String, dynamic>{'message': 'Server error'},
          ),
        ));

        await container.read(adminProvider.notifier).fetchTickets();

        final state = container.read(adminProvider);
        expect(state.tickets, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('updateTicketStatus', () {
      test('updates ticket status on success', () async {
        // First load tickets
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminTickets,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {
              'data': [_ticketJson()],
            });

        await container.read(adminProvider.notifier).fetchTickets();
        expect(container.read(adminProvider).tickets.first.status, 'OPEN');

        // Stub PATCH
        when<Future<Map<String, dynamic>>>(() => mockApiClient.patch(
              ApiConstants.adminTicket('ticket-1'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => {'data': {'message': 'Updated'}});

        // Act
        await container
            .read(adminProvider.notifier)
            .updateTicketStatus('ticket-1', 'IN_PROGRESS');

        // Assert
        final state = container.read(adminProvider);
        expect(state.tickets.first.status, 'IN_PROGRESS');
        expect(state.isLoading, false);
        expect(state.error, isNull);
      });

      test('sets error on failure', () async {
        // First load tickets
        when<Future<Map<String, dynamic>>>(() => mockApiClient.get(
              ApiConstants.adminTickets,
              queryParams: any(named: 'queryParams'),
            )).thenAnswer((_) async => {
              'data': [_ticketJson()],
            });

        await container.read(adminProvider.notifier).fetchTickets();
        expect(container.read(adminProvider).tickets.first.status, 'OPEN');

        // Stub PATCH to fail
        when<Future<Map<String, dynamic>>>(() => mockApiClient.patch(
              ApiConstants.adminTicket('ticket-1'),
              body: any(named: 'body'),
            )).thenThrow(DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.adminTicket('ticket-1')),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions:
                RequestOptions(path: ApiConstants.adminTicket('ticket-1')),
            statusCode: 400,
            data: <String, dynamic>{'message': 'Invalid status'},
          ),
        ));

        // Act
        await container
            .read(adminProvider.notifier)
            .updateTicketStatus('ticket-1', 'INVALID');

        // Assert
        final state = container.read(adminProvider);
        expect(state.tickets.first.status, 'OPEN'); // Unchanged
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });
  });
}

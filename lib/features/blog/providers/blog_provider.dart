import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/blog_post.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class BlogState {
  final List<BlogPost> posts;
  final BlogPost? selectedPost;
  final bool isLoading;
  final String? error;

  const BlogState({
    this.posts = const [],
    this.selectedPost,
    this.isLoading = false,
    this.error,
  });

  BlogState copyWith({
    List<BlogPost>? posts,
    BlogPost? selectedPost,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelectedPost = false,
  }) {
    return BlogState(
      posts: posts ?? this.posts,
      selectedPost:
          clearSelectedPost ? null : (selectedPost ?? this.selectedPost),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final blogProvider = StateNotifierProvider<BlogNotifier, BlogState>((ref) {
  return BlogNotifier();
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class BlogNotifier extends StateNotifier<BlogState> {
  final ApiClient _api;

  BlogNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const BlogState());

  /// GET /api/blog
  Future<void> fetchPosts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.blog,
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final posts = rawList
          .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
          .toList();

      state = BlogState(posts: posts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// GET /api/blog/[slug]
  Future<void> fetchPost(String slug) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.blogPost(slug),
      );

      final post = BlogPost.fromJson(result['data'] as Map<String, dynamic>);

      state = state.copyWith(selectedPost: post, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Something went wrong. Please try again.';
    }
    return error.toString();
  }
}

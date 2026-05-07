import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/benefit.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/data/models/user.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerProfileState {
  final Profile? profile;
  final User? user;
  final List<Service> services;
  final List<Package> packages;
  final List<Testimonial> testimonials;
  final List<Benefit> benefits;
  final bool isLoading;
  final String? error;
  final int activeTab;

  const TrainerProfileState({
    this.profile,
    this.user,
    this.services = const [],
    this.packages = const [],
    this.testimonials = const [],
    this.benefits = const [],
    this.isLoading = false,
    this.error,
    this.activeTab = 0,
  });

  TrainerProfileState copyWith({
    Profile? profile,
    User? user,
    List<Service>? services,
    List<Package>? packages,
    List<Testimonial>? testimonials,
    List<Benefit>? benefits,
    bool? isLoading,
    String? error,
    int? activeTab,
    bool clearError = false,
  }) {
    return TrainerProfileState(
      profile: profile ?? this.profile,
      user: user ?? this.user,
      services: services ?? this.services,
      packages: packages ?? this.packages,
      testimonials: testimonials ?? this.testimonials,
      benefits: benefits ?? this.benefits,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerProfileNotifier extends StateNotifier<TrainerProfileState> {
  final ApiClient _apiClient;

  TrainerProfileNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerProfileState());

  // -- Fetch all profile data --

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch profile
      final profileResponse = await _apiClient.get(
        ApiConstants.profileMe,
        fromJson: (json) => Profile.fromJson(json),
      );

      // Fetch services
      final servicesResponse = await _apiClient.get(
        ApiConstants.profileMeServices,
        fromJson: (json) => (json['data'] as List<dynamic>?)
                ?.map((e) => Service.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

      // Fetch packages
      final packagesResponse = await _apiClient.get(
        ApiConstants.profileMePackages,
        fromJson: (json) => (json['data'] as List<dynamic>?)
                ?.map((e) => Package.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

      // Fetch testimonials
      final testimonialsResponse = await _apiClient.get(
        ApiConstants.profileMeTestimonials,
        fromJson: (json) => (json['data'] as List<dynamic>?)
                ?.map((e) => Testimonial.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

      // Fetch benefits
      final benefitsResponse = await _apiClient.get(
        ApiConstants.profileMeBenefits,
        fromJson: (json) => (json['data'] as List<dynamic>?)
                ?.map((e) => Benefit.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

      state = state.copyWith(
        profile: profileResponse,
        services: servicesResponse,
        packages: packagesResponse,
        testimonials: testimonialsResponse,
        benefits: benefitsResponse,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Update text content --

  Future<void> updateTextContent(String field, String content) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.put(
        ApiConstants.profileMeTextContent,
        body: {field: content},
      );

      // Refresh profile to get updated data
      await fetchProfile();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Services CRUD --

  Future<void> addService(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post(
        ApiConstants.profileMeServices,
        body: data,
        fromJson: (json) => Service.fromJson(json),
      );

      state = state.copyWith(
        services: [...state.services, response],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.put(
        '${ApiConstants.profileMeServices}/$id',
        body: data,
        fromJson: (json) => Service.fromJson(json),
      );

      final updatedServices = state.services.map((service) {
        return service.id == id ? response : service;
      }).toList();

      state = state.copyWith(
        services: updatedServices,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  Future<void> deleteService(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.profileMeServices}/$id');

      state = state.copyWith(
        services: state.services.where((service) => service.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Packages CRUD --

  Future<void> addPackage(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post(
        ApiConstants.profileMePackages,
        body: data,
        fromJson: (json) => Package.fromJson(json),
      );

      state = state.copyWith(
        packages: [...state.packages, response],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.put(
        '${ApiConstants.profileMePackages}/$id',
        body: data,
        fromJson: (json) => Package.fromJson(json),
      );

      final updatedPackages = state.packages.map((package) {
        return package.id == id ? response : package;
      }).toList();

      state = state.copyWith(
        packages: updatedPackages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  Future<void> deletePackage(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.profileMePackages}/$id');

      state = state.copyWith(
        packages: state.packages.where((package) => package.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Reorder packages (optimistic local update) --

  void reorderPackages(List<Package> updatedPackages) {
    state = state.copyWith(packages: updatedPackages);
  }

  /// Sets a package as the default (active) package.
  Future<void> setDefaultPackage(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.put(
        '${ApiConstants.profileMePackages}/$id',
        body: {'is_active': true},
      );

      // Deactivate all others locally, activate the target
      final updatedPackages = state.packages.map((p) {
        return Package(
          id: p.id,
          name: p.name,
          description: p.description,
          price: p.price,
          numberOfSessions: p.numberOfSessions,
          isActive: p.id == id,
          stripeProductId: p.stripeProductId,
          stripePriceId: p.stripePriceId,
          trainerId: p.trainerId,
          createdAt: p.createdAt,
          updatedAt: p.updatedAt,
          deletedAt: p.deletedAt,
        );
      }).toList();

      state = state.copyWith(
        packages: updatedPackages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Testimonials CRUD --

  Future<void> addTestimonial(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post(
        ApiConstants.profileMeTestimonials,
        body: data,
        fromJson: (json) => Testimonial.fromJson(json),
      );

      state = state.copyWith(
        testimonials: [...state.testimonials, response],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Sends a request to a client asking them to leave a review/testimonial.
  Future<void> requestTestimonialReview(String clientId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.post(
        '${ApiConstants.profileMeTestimonials}/request-review',
        body: {'client_id': clientId},
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  Future<void> deleteTestimonial(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.profileMeTestimonials}/$id');

      state = state.copyWith(
        testimonials: state.testimonials.where((testimonial) => testimonial.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Benefits CRUD --

  Future<void> addBenefit(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post(
        ApiConstants.profileMeBenefits,
        body: data,
        fromJson: (json) => Benefit.fromJson(json),
      );

      state = state.copyWith(
        benefits: [...state.benefits, response],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  Future<void> deleteBenefit(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.profileMeBenefits}/$id');

      state = state.copyWith(
        benefits: state.benefits.where((benefit) => benefit.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Reorder services (optimistic local update) --

  void reorderServices(List<Service> updatedServices) {
    state = state.copyWith(services: updatedServices);
  }

  // -- Active tab --

  void setActiveTab(int tab) {
    state = state.copyWith(activeTab: tab);
  }

  // -- Helpers --

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
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            return 'Unauthorized. Please log in again.';
          }
          if (error.response?.statusCode == 429) {
            return 'Too many attempts. Please try again later.';
          }
          break;
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final trainerProfileProvider =
    StateNotifierProvider<TrainerProfileNotifier, TrainerProfileState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerProfileNotifier(apiClient: apiClient);
});
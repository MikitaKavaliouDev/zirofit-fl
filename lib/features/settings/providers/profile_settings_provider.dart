import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProfileSettingsState {
  final String name;
  final String email;
  final String bio;
  final List<String> locations;
  final String philosophy;
  final String methodology;
  final String certifications;
  final String qualifications;
  final double height;
  final double weight;
  final String? avatarUrl;
  final XFile? pendingAvatar;
  final bool isLoading;
  final bool isSaving;
  final bool isTrainer;
  final String? error;
  final String? successMessage;

  // Originals for change tracking
  final String _originalName;
  final String _originalBio;
  final List<String> _originalLocations;
  final String _originalPhilosophy;
  final String _originalMethodology;
  final String _originalCertifications;
  final String _originalQualifications;
  final double _originalHeight;
  final double _originalWeight;

  bool get isChanged =>
      pendingAvatar != null ||
      name != _originalName ||
      bio != _originalBio ||
      locations.length != _originalLocations.length ||
      !locations.every(_originalLocations.contains) ||
      !_originalLocations.every(locations.contains) ||
      philosophy != _originalPhilosophy ||
      methodology != _originalMethodology ||
      certifications != _originalCertifications ||
      qualifications != _originalQualifications ||
      height != _originalHeight ||
      weight != _originalWeight;

  const ProfileSettingsState({
    this.name = '',
    this.email = '',
    this.bio = '',
    this.locations = const [],
    this.philosophy = '',
    this.methodology = '',
    this.certifications = '',
    this.qualifications = '',
    this.height = 0,
    this.weight = 0,
    this.avatarUrl,
    this.pendingAvatar,
    this.isLoading = false,
    this.isSaving = false,
    this.isTrainer = false,
    this.error,
    this.successMessage,
    String originalName = '',
    String originalBio = '',
    List<String> originalLocations = const [],
    String originalPhilosophy = '',
    String originalMethodology = '',
    String originalCertifications = '',
    String originalQualifications = '',
    double originalHeight = 0,
    double originalWeight = 0,
  })  : _originalName = originalName,
        _originalBio = originalBio,
        _originalLocations = originalLocations,
        _originalPhilosophy = originalPhilosophy,
        _originalMethodology = originalMethodology,
        _originalCertifications = originalCertifications,
        _originalQualifications = originalQualifications,
        _originalHeight = originalHeight,
        _originalWeight = originalWeight;

  ProfileSettingsState copyWith({
    String? name,
    String? email,
    String? bio,
    List<String>? locations,
    String? philosophy,
    String? methodology,
    String? certifications,
    String? qualifications,
    double? height,
    double? weight,
    String? avatarUrl,
    XFile? pendingAvatar,
    bool? isLoading,
    bool? isSaving,
    bool? isTrainer,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    // originals
    String? originalName,
    String? originalBio,
    List<String>? originalLocations,
    String? originalPhilosophy,
    String? originalMethodology,
    String? originalCertifications,
    String? originalQualifications,
    double? originalHeight,
    double? originalWeight,
  }) {
    return ProfileSettingsState(
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      locations: locations ?? this.locations,
      philosophy: philosophy ?? this.philosophy,
      methodology: methodology ?? this.methodology,
      certifications: certifications ?? this.certifications,
      qualifications: qualifications ?? this.qualifications,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pendingAvatar: pendingAvatar ?? this.pendingAvatar,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isTrainer: isTrainer ?? this.isTrainer,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      originalName: originalName ?? _originalName,
      originalBio: originalBio ?? _originalBio,
      originalLocations: originalLocations ?? _originalLocations,
      originalPhilosophy: originalPhilosophy ?? _originalPhilosophy,
      originalMethodology: originalMethodology ?? _originalMethodology,
      originalCertifications: originalCertifications ?? _originalCertifications,
      originalQualifications: originalQualifications ?? _originalQualifications,
      originalHeight: originalHeight ?? _originalHeight,
      originalWeight: originalWeight ?? _originalWeight,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProfileSettingsNotifier extends StateNotifier<ProfileSettingsState> {
  final ApiClient _api;

  ProfileSettingsNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const ProfileSettingsState());

  // -- Load profile --

  Future<void> loadProfile({required bool isTrainer}) async {
    state = state.copyWith(
      isLoading: true,
      isTrainer: isTrainer,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.profileMe,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;

      // Map from API response (supports both snake_case and camelCase)
      final name = (data['name'] ?? data['Name'] ?? '') as String;
      final email = (data['email'] ?? data['Email'] ?? '') as String;
      final bio = (data['bio'] ?? data['about_me'] ?? data['aboutMe'] ?? '')
          as String;
      final height =
          ((data['height'] ?? data['Height'] ?? 0) as num).toDouble();
      final weight =
          ((data['weight'] ?? data['Weight'] ?? 0) as num).toDouble();
      final avatarUrl =
          (data['avatar_url'] ?? data['avatarUrl'] ?? data['profilePhotoPath'])
              as String?;
      final philosophy =
          (data['philosophy'] ?? data['Philosophy'] ?? '') as String;
      final methodology =
          (data['methodology'] ?? data['Methodology'] ?? '') as String;
      final certifications =
          (data['certifications'] ?? data['Certifications'] ?? '') as String;
      final qualifications =
          (data['qualifications'] ?? data['Qualifications'] ?? '') as String;

      // Locations from user or profile
      final rawLocations = data['locations'] ?? data['Locations'];
      final List<String> locations;
      if (rawLocations is List) {
        locations = rawLocations.map((e) => e.toString()).toList();
      } else if (data['location'] != null) {
        locations = [data['location'] as String];
      } else {
        locations = [];
      }

      state = ProfileSettingsState(
        name: name,
        email: email,
        bio: bio,
        locations: locations,
        philosophy: philosophy,
        methodology: methodology,
        certifications: certifications,
        qualifications: qualifications,
        height: height,
        weight: weight,
        avatarUrl: avatarUrl,
        isLoading: false,
        isSaving: false,
        isTrainer: isTrainer,
        originalName: name,
        originalBio: bio,
        originalLocations: List.of(locations),
        originalPhilosophy: philosophy,
        originalMethodology: methodology,
        originalCertifications: certifications,
        originalQualifications: qualifications,
        originalHeight: height,
        originalWeight: weight,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Field setters --

  void setName(String value) => state = state.copyWith(name: value);
  void setBio(String value) => state = state.copyWith(bio: value);
  void setPhilosophy(String value) =>
      state = state.copyWith(philosophy: value);
  void setMethodology(String value) =>
      state = state.copyWith(methodology: value);
  void setCertifications(String value) =>
      state = state.copyWith(certifications: value);
  void setQualifications(String value) =>
      state = state.copyWith(qualifications: value);
  void setHeight(double value) => state = state.copyWith(height: value);
  void setWeight(double value) => state = state.copyWith(weight: value);

  void setPendingAvatar(XFile file) =>
      state = state.copyWith(pendingAvatar: file);

  void clearPendingAvatar() => state = state.copyWith(pendingAvatar: null);

  void addLocation(String location) {
    if (location.trim().isEmpty) return;
    final updated = List<String>.from(state.locations)..add(location.trim());
    state = state.copyWith(locations: updated);
  }

  void removeLocation(int index) {
    if (index < 0 || index >= state.locations.length) return;
    final updated = List<String>.from(state.locations)..removeAt(index);
    state = state.copyWith(locations: updated);
  }

  // -- Save profile --

  Future<bool> saveProfile() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      // 1. Upload avatar if changed
      String? newAvatarUrl;
      if (state.pendingAvatar != null) {
        try {
          newAvatarUrl = await _uploadAvatar(state.pendingAvatar!);
        } catch (e) {
          debugPrint('Avatar upload failed, continuing with profile save: $e');
        }
      }

      // 2. Build profile payload
      final body = <String, dynamic>{
        'name': state.name,
        'bio': state.bio,
        'location': state.locations.isNotEmpty ? state.locations.first : '',
        'locations': state.locations,
        'height': state.height > 0 ? state.height : null,
        'weight': state.weight > 0 ? state.weight : null,
      };

      // Include avatar URL if uploaded
      if (newAvatarUrl != null) {
        body['avatar_url'] = newAvatarUrl;
      } else if (state.avatarUrl != null) {
        body['avatar_url'] = state.avatarUrl;
      }

      // Trainer-only fields
      if (state.isTrainer) {
        body['philosophy'] =
            state.philosophy.isEmpty ? null : state.philosophy;
        body['methodology'] =
            state.methodology.isEmpty ? null : state.methodology;
        body['certifications'] =
            state.certifications.isEmpty ? null : state.certifications;
        body['qualifications'] =
            state.qualifications.isEmpty ? null : state.qualifications;
      }

      // 3. Save via PUT /trainer/settings
      await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerSettings,
        body: body,
      );

      // 4. Update originals so button disables
      state = state.copyWith(
        isSaving: false,
        pendingAvatar: null,
        avatarUrl: newAvatarUrl ?? state.avatarUrl,
        successMessage: 'Profile saved successfully',
        originalName: state.name,
        originalBio: state.bio,
        originalLocations: List.of(state.locations),
        originalPhilosophy: state.philosophy,
        originalMethodology: state.methodology,
        originalCertifications: state.certifications,
        originalQualifications: state.qualifications,
        originalHeight: state.height,
        originalWeight: state.weight,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // -- Avatar upload --

  Future<String> _uploadAvatar(XFile file) async {
    // Use the registered trainer avatar upload endpoint
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        file.path,
        filename: 'profile_avatar.jpg',
      ),
    });

    final response = await _api.dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.trainerProfileAvatar}',
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    final resultData = data['data'] as Map<String, dynamic>? ?? data;
    return (resultData['url'] ?? resultData['avatarUrl'] ?? resultData['path']
        as String);
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

final profileSettingsProvider = StateNotifierProvider<
    ProfileSettingsNotifier, ProfileSettingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileSettingsNotifier(apiClient: apiClient);
});

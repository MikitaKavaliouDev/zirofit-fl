import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_package.dart';
import 'package:zirofit_fl/data/models/package.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientPackagesState {
  final bool isLoading;
  final List<ClientPackage> purchased;
  final List<Package> available;
  final String? error;
  final bool isPurchasing;

  const ClientPackagesState({
    this.isLoading = false,
    this.purchased = const [],
    this.available = const [],
    this.error,
    this.isPurchasing = false,
  });

  /// Build a map from packageId → Package for name resolution.
  Map<String, Package> get packageMap {
    final map = <String, Package>{};
    for (final pkg in available) {
      map[pkg.id] = pkg;
    }
    return UnmodifiableMapView(map);
  }

  bool get hasError => error != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientPackagesState &&
          isLoading == other.isLoading &&
          listEquals(purchased, other.purchased) &&
          listEquals(available, other.available) &&
          error == other.error &&
          isPurchasing == other.isPurchasing;

  @override
  int get hashCode => Object.hash(
        isLoading,
        Object.hashAll(purchased),
        Object.hashAll(available),
        error,
        isPurchasing,
      );

  ClientPackagesState copyWith({
    bool? isLoading,
    List<ClientPackage>? purchased,
    List<Package>? available,
    bool clearError = false,
    String? error,
    bool? isPurchasing,
  }) {
    return ClientPackagesState(
      isLoading: isLoading ?? this.isLoading,
      purchased: purchased ?? this.purchased,
      available: available ?? this.available,
      error: clearError ? null : (error ?? this.error),
      isPurchasing: isPurchasing ?? this.isPurchasing,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientPackagesNotifier extends StateNotifier<ClientPackagesState> {
  final ApiClient _apiClient;

  ClientPackagesNotifier(this._apiClient) : super(const ClientPackagesState());

  /// Fetch both purchased and available packages in parallel.
  Future<void> fetchPackages() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _fetchPurchased(),
        _fetchAvailable(),
      ]);

      state = state.copyWith(
        purchased: results[0] as List<ClientPackage>,
        available: results[1] as List<Package>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  Future<List<ClientPackage>> _fetchPurchased() async {
    final response = await _apiClient.get(
      ApiConstants.clientMyPackages,
    );
    return _parseList<ClientPackage>(response, ClientPackage.fromJson);
  }

  Future<List<Package>> _fetchAvailable() async {
    final response = await _apiClient.get(
      ApiConstants.clientAvailablePackages,
    );
    return _parseList<Package>(response, Package.fromJson);
  }

  /// Purchase a package and open the checkout URL.
  Future<void> purchasePackage(String packageId) async {
    state = state.copyWith(isPurchasing: true);

    try {
      final response = await _apiClient.post(
        ApiConstants.clientPurchasePackage,
        body: {'package_id': packageId},
      );

      final url = _extractUrl(response);
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }

      // Re-fetch packages to reflect the new purchase.
      await fetchPackages();
    } catch (e) {
      state = state.copyWith(
        isPurchasing: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Extracts a URL string from various API response shapes.
  String? _extractUrl(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['url'] as String?;
    }
    if (data is String) return data;
    if (response['url'] is String) return response['url'] as String;
    return null;
  }

  List<T> _parseList<T>(
    Map<String, dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response['data'];
    final rawList = data is Map ? data['packages'] ?? data['items'] : data;

    if (rawList is List) {
      return rawList
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final clientPackagesProvider =
    StateNotifierProvider<ClientPackagesNotifier, ClientPackagesState>((ref) {
  final apiClient = ApiClient.instance;
  return ClientPackagesNotifier(apiClient);
});

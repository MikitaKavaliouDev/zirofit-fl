import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

/// Screen that handles OAuth callback deep links.
///
/// Parses [access_token] and [refresh_token] from the URL query parameters,
/// persists them via [SecureStorage], then calls [AuthNotifier.refreshSession]
/// to bootstrap the user session.
///
/// Shows a loading spinner while processing and an error state if tokens are
/// missing or the session refresh fails. On success the [GoRouter] redirect
/// logic (defined in [routerProvider]) handles navigation to the appropriate
/// dashboard.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  /// Query parameters from the deep link URL.
  final Map<String, String> queryParams;

  const AuthCallbackScreen({super.key, required this.queryParams});

  @override
  ConsumerState<AuthCallbackScreen> createState() =>
      _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _isProcessing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _processCallback());
  }

  Future<void> _processCallback() async {
    final accessToken = widget.queryParams['access_token'];
    final refreshToken = widget.queryParams['refresh_token'];

    if (accessToken == null || refreshToken == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Invalid authentication callback: missing tokens';
        });
      }
      return;
    }

    try {
      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await ref.read(authProvider.notifier).refreshSession();
      // On success the GoRouter redirect handles navigation away from this
      // screen — no need to update local state.
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Authentication failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _isProcessing ? _buildLoading(theme) : _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Completing authentication...'),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Success — redirect has already navigated away; this is a brief
    // fallback before the widget is unmounted.
    if (_error == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Failed',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/auth/login'),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}

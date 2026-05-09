import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

// ---------------------------------------------------------------------------
// API provider
// ---------------------------------------------------------------------------

final _apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('Must be overridden in tests');
});

// ---------------------------------------------------------------------------
// Dialog widget
// ---------------------------------------------------------------------------

/// A modal bottom sheet for quickly adding a new client.
///
/// Usage:
/// ```dart
/// final result = await AddClientSheet.show(context);
/// if (result == true) { /* refresh client list */ }
/// ```
class AddClientSheet extends ConsumerStatefulWidget {
  const AddClientSheet({super.key});

  /// Shows the dialog as a modal bottom sheet.
  ///
  /// Returns `true` if a client was successfully created, `null` if
  /// the user dismissed the sheet without creating.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddClientSheetShell(),
    );
  }

  @override
  ConsumerState<AddClientSheet> createState() => _AddClientSheetState();
}

/// Thin wrapper so the static [show] method can pass a [Consumer].
class _AddClientSheetShell extends ConsumerWidget {
  const _AddClientSheetShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AddClientSheet();
  }
}

class _AddClientSheetState extends ConsumerState<AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isValid {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) return false;
    return _isValidEmail(email);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _submit() async {
    if (!_isValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(_apiClientProvider);

      await apiClient.post(
        '/clients',
        body: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      final response = e.response;
      if (response?.statusCode == 409) {
        // User exists - show alert
        if (mounted) {
          _showUserExistsDialog();
        }
      } else {
        setState(() {
          _errorMessage = _extractErrorMessage(e);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return data['message'] as String? ??
          data['error'] as String? ??
          'Failed to add client';
    }
    return e.message ?? 'Failed to add client';
  }

  Future<void> _showUserExistsDialog() async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Exists'),
        content: const Text(
          'This email is already registered on Ziro Fit. '
          'Would you like to request to connect with them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Request Connection'),
          ),
        ],
      ),
    );

    if (shouldRequest == true && mounted) {
      // TODO: Implement connection request - call API to request connection
      // For now, we'll just return true since client is already created above
      // The actual connection request API would be: POST /trainer/clients/{id}/request-connect
      try {
        debugPrint('ℹ️ add_client_sheet: Connection request would be sent for new client');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e, st) {
        debugPrint('❌ add_client_sheet ERROR: $e');
        debugPrint('Stack: $st');
        if (mounted) {
          Navigator.of(context).pop(true); // Still return true, client was created
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              'Add a client to invite them to Ziro Fit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            // Submit button
            FilledButton(
              onPressed: _isValid && !_isLoading ? _submit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Add Client',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
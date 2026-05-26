import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/clients/providers/client_invite_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';

class InviteClientScreen extends ConsumerStatefulWidget {
  const InviteClientScreen({super.key});

  @override
  ConsumerState<InviteClientScreen> createState() =>
      _InviteClientScreenState();
}

class _InviteClientScreenState extends ConsumerState<InviteClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final hasEmail = email.isNotEmpty;
    final hasPhone = phone.isNotEmpty;
    if (name.isEmpty) return false;
    if (!hasEmail && !hasPhone) return false;
    if (hasEmail && !_isValidEmail(email)) return false;
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();

    // Check email existence first (only if email was provided)
    if (email.isNotEmpty) {
      final inviteNotifier = ref.read(clientInviteProvider.notifier);
      final exists = await inviteNotifier.checkEmail(email);
      if (!mounted) return;

      if (exists) {
        setState(() => _isSubmitting = false);
        _showUserExistsDialog();
        return;
      }
      if (!mounted) return;
    }

    // Use optimistic add via clientListProvider
    // This creates a temp client in the list immediately,
    // inserts at index 0, and saves to cache.
    // On API success: temp client is replaced with server client.
    // On API failure: temp client is removed and error is shown.
    final error = await ref.read(clientListProvider.notifier).inviteClient(
      name: name,
      email: email.isNotEmpty ? email : '${name.replaceAll(' ', '.').toLowerCase()}@pending.zirofit',
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (error == null) {
      // Success: show confirmation and navigate back
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invitation Sent'),
          content: const Text(
            'Your invitation has been sent successfully.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      ref.read(clientInviteProvider.notifier).reset();
      context.pop();
    } else {
      // Error: show error dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invitation Failed'),
          content: Text(error),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showUserExistsDialog() async {
    final shouldLink = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Already Exists'),
        content: const Text(
          'This email is already registered on Ziro Fit. '
          'Would you like to send a connection request instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Link Request'),
          ),
        ],
      ),
    );

    if (shouldLink == true && mounted) {
      setState(() => _isSubmitting = true);
      await ref
          .read(clientInviteProvider.notifier)
          .linkExisting(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientInviteProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Client'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Send an invitation to a new client',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter client name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'client@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!_isValidEmail(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // OR divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  hintText: '+1 (555) 123-4567',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Optional message / personal note
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Personal message (optional)',
                  hintText:
                      "I'd like to connect with you on Ziro Fit to manage your training!",
                  prefixIcon: const Icon(Icons.message_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),

              // Error message
              if (state.hasError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Send invite button
              FilledButton(
                onPressed: (_isFormValid && !_isSubmitting)
                    ? () => _handleSendInvite()
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Invitation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // Cancel button
              TextButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

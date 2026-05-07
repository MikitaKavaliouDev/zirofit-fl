import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/clients/providers/client_invite_provider.dart';

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
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    return name.isNotEmpty && _isValidEmail(email);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(clientInviteProvider.notifier);

    // First check if the user already exists
    final exists = await notifier.checkEmail(_emailController.text.trim());
    if (!mounted) return;

    if (exists) {
      _showUserExistsDialog();
      return;
    }

    if (!mounted) return;
    await notifier.invite(
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      message: _messageController.text.trim(),
    );
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
      await ref
          .read(clientInviteProvider.notifier)
          .linkExisting(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientInviteProvider);
    final theme = Theme.of(context);

    // Success state
    if (state.isSuccess && state.invitedEmail != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invite Client'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Invitation sent to',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  state.invitedEmail!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    ref.read(clientInviteProvider.notifier).reset();
                    context.pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!_isValidEmail(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Optional message field
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Add a personal note...',
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
                onPressed: (_isFormValid && !state.isLoading)
                    ? () => _handleSendInvite()
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
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
                onPressed: state.isLoading ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

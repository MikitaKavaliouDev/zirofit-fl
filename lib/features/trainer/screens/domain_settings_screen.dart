import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/settings/providers/domain_provider.dart';

class DomainSettingsScreen extends ConsumerStatefulWidget {
  const DomainSettingsScreen({super.key});

  @override
  ConsumerState<DomainSettingsScreen> createState() =>
      _DomainSettingsScreenState();
}

class _DomainSettingsScreenState extends ConsumerState<DomainSettingsScreen> {
  final _domainController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(domainProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Domain'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Domain',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set a custom domain for your trainer profile page.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MessageBanner(
                    message: state.error!,
                    isError: true,
                    onDismiss: () {
                      ref.read(domainProvider.notifier).reset();
                    },
                  ),
                ),

              // Current domain display
              if (state.domain != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Current Domain',
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            _VerificationBadge(
                              isVerified: state.isVerified,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.domain!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!state.isVerified) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Domain not yet verified. Please configure your DNS settings and click Verify.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Domain input
              Text(
                'Enter Domain',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _domainController,
                decoration: InputDecoration(
                  hintText: 'e.g., profile.yourdomain.com',
                  border: const OutlineInputBorder(),
                  suffixIcon: state.domain != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _domainController.clear();
                          },
                        )
                      : null,
                ),
                enabled: !state.isAdding,
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a domain';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$')
                      .hasMatch(value.trim())) {
                    return 'Please enter a valid domain';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Add / Update button
              FilledButton.icon(
                onPressed: state.isAdding
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          ref
                              .read(domainProvider.notifier)
                              .addDomain(_domainController.text.trim());
                        }
                      },
                icon: state.isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  state.domain != null ? 'Update Domain' : 'Add Domain',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              // Verify button
              if (state.domain != null)
                OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          ref.read(domainProvider.notifier).verifyDomain();
                        },
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified),
                  label: Text(
                    state.isLoading ? 'Verifying...' : 'Verify Domain',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verification Badge
// ---------------------------------------------------------------------------

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;

  const _VerificationBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            'Pending',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message Banner
// ---------------------------------------------------------------------------

class _MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.primaryContainer;
    final fgColor = isError
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onPrimaryContainer;
    final icon = isError ? Icons.error : Icons.check_circle;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: fgColor),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: fgColor),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

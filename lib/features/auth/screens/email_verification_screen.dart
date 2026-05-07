import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/auth/providers/email_verification_provider.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  @override
  void initState() {
    super.initState();
    // Start polling after the first frame so that build() doesn't run during
    // the widget's initialisation phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(emailVerificationProvider.notifier).startPolling();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailVerificationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Auto-navigate when email is confirmed.
    ref.listen<EmailVerificationState>(
      emailVerificationProvider,
      (_, next) {
        if (next.isConfirmed && mounted) {
          context.go('/auth/login');
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                // Mail icon
                Icon(
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // Heading
                Text(
                  'Check your email',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Instruction text
                Text(
                  'We\'ve sent a verification link to',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),

                // Email address
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                // Polling indicator
                if (state.isPolling) _buildPollingIndicator(),
                if (state.hasTimedOut) _buildTimeoutMessage(theme),
                if (state.isConfirmed) _buildSuccessMessage(colorScheme),

                const SizedBox(height: 32),

                // Resend button
                _buildResendButton(state, colorScheme),

                const SizedBox(height: 16),

                // Resend feedback
                if (state.resendStatus == ResendStatus.sent)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Verification email resent!',
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),

                if (state.resendStatus == ResendStatus.error &&
                    state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -- Polling indicator ----------------------------------------------------

  Widget _buildPollingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Waiting for verification',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 8),
        const _AnimatedDots(),
      ],
    );
  }

  // -- Timeout message ------------------------------------------------------

  Widget _buildTimeoutMessage(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, size: 32, color: Colors.orange.shade600),
        const SizedBox(height: 8),
        Text(
          'Still waiting? It may take a few minutes.\n'
          'Make sure to check your spam folder.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // -- Success message ------------------------------------------------------

  Widget _buildSuccessMessage(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 48, color: Colors.green.shade600),
        const SizedBox(height: 8),
        Text(
          'Email verified! Redirecting...',
          style: TextStyle(color: Colors.green.shade700),
        ),
      ],
    );
  }

  // -- Resend button --------------------------------------------------------

  Widget _buildResendButton(EmailVerificationState state, ColorScheme colorScheme) {
    final isSending = state.resendStatus == ResendStatus.sending;

    return OutlinedButton.icon(
      onPressed: isSending || state.isConfirmed
          ? null
          : () => ref.read(emailVerificationProvider.notifier).resendEmail(),
      icon: isSending
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
      label: const Text('Resend email'),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated dots widget
// ---------------------------------------------------------------------------

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> {
  int _dotCount = 1;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() => _dotCount = _dotCount < 3 ? _dotCount + 1 : 1);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Opacity(
          opacity: i < _dotCount ? 1.0 : 0.2,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }),
    );
  }
}

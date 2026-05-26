import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A widget that generates and displays a QR code for a trainer's
/// referral/client-add link.
///
/// Shows the QR code image centered with an optional label below.
/// Matches iOS style: simple, clean, white background with dark QR code.
class QrCodeGenerator extends StatelessWidget {
  const QrCodeGenerator({
    super.key,
    required this.data,
    this.label,
    this.size = 200,
  });

  /// The data (URL or identifier) to encode into the QR code.
  final String data;

  /// An optional label displayed below the QR code.
  final String? label;

  /// The size of the QR code square in logical pixels.
  /// Defaults to 200.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Handle empty data gracefully
    if (data.isEmpty) {
      return _buildErrorState(theme, 'No data to encode');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // QR code card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1F2937),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1F2937),
            ),
            gapless: false,
            errorStateBuilder: (ctx, error) {
              return Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              );
            },
          ),
        ),

        // Optional label below QR code
        if (label != null && label!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

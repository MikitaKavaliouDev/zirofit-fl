import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/clients/widgets/qr_code_generator.dart';

/// Full-screen digital business card showing the trainer's QR code.
///
/// Encodes `https://ziro.fit/trainer/{username}` so clients can scan and
/// quickly access the trainer's public profile.
class TrainerQrCodeScreen extends ConsumerStatefulWidget {
  const TrainerQrCodeScreen({super.key});

  @override
  ConsumerState<TrainerQrCodeScreen> createState() =>
      _TrainerQrCodeScreenState();
}

class _TrainerQrCodeScreenState extends ConsumerState<TrainerQrCodeScreen> {
  final _qrRepaintKey = GlobalKey();

  Future<Uint8List?> _captureQrBytes() async {
    final boundary = _qrRepaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = ref.watch(
      authProvider.select((s) => s.user?.name ?? ''),
    );
    final profileUrl = 'https://ziro.fit/trainer/$userName';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Business Card'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR code card
                RepaintBoundary(
                  key: _qrRepaintKey,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    color: Colors.white,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrCodeGenerator(
                            data: profileUrl,
                            size: 220,
                          ),
                          const SizedBox(height: 20),
                          // Trainer name
                          Text(
                            userName.isNotEmpty ? userName : 'Your Business Card',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Profile URL
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F2937).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              profileUrl,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1F2937).withValues(alpha: 0.6),
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: profileUrl),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile link copied to clipboard!',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download_outlined,
                        label: 'Download',
                        onTap: () async {
                          final bytes = await _captureQrBytes();
                          if (bytes == null) return;
                          final dir = await getTemporaryDirectory();
                          final file = await File(
                            '${dir.path}/trainer_qr_$userName.png',
                          ).writeAsBytes(bytes);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Saved to ${file.path}'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Scan this QR code to view my trainer profile',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A styled action button used in the QR code screen.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F2937),
          side: const BorderSide(
            color: Color(0xFF1F2937),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

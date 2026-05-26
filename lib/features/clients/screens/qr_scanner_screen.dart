import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A full-screen QR scanner view that scans QR codes to find/identify clients.
///
/// When a QR code is detected, the scanned data is returned via Navigator.pop
/// as a [String]. If the user cancels, null is returned.
///
/// Usage:
/// ```dart
/// final result = await Navigator.of(context).push<String>(
///   MaterialPageRoute(builder: (_) => const QrScannerScreen()),
/// );
/// if (result != null) {
///   // Handle scanned QR data
/// }
/// ```
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not configured, stop and start to reset it.
    if (!_controller.value.isRunning) return;
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _controller.stop();
      case AppLifecycleState.resumed:
        _controller.start();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    // Haptic-like feedback — stop the scanner and return the result
    _controller.stop();

    if (!mounted) return;

    // Show a brief success indicator, then return the scanned value
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned: $rawValue'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    // Return the scanned data after a brief delay so the user sees the feedback
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.of(context).pop(rawValue);
      }
    });
  }

  void _handleCancel() {
    _controller.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview for QR scanning
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return _buildErrorView(theme, error);
            },
          ),

          // Overlay UI
          _buildOverlay(theme),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: _handleCancel,
                icon: const Icon(Icons.close_rounded),
                iconSize: 28,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(ThemeData theme) {
    return Column(
      children: [
        const Spacer(flex: 3),

        // Scan frame area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const Spacer(flex: 1),

        // Hint text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Place QR code in frame',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        // Cancel button
        TextButton.icon(
          onPressed: _handleCancel,
          icon: const Icon(Icons.close, color: Colors.white70),
          label: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),

        // Bottom padding
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildErrorView(ThemeData theme, MobileScannerException error) {
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                error.errorDetails?.message ?? error.errorCode.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (isPermissionDenied)
                Text(
                  'Camera access is required to scan QR codes. '
                  'Please enable camera permission in your device settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              if (!isPermissionDenied)
                FilledButton.icon(
                  onPressed: () {
                    _controller.start();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

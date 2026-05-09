import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'bootstrap.dart';
import 'core/providers/global_logger.dart';
import 'shared/widgets/ziro_data_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    GlobalLogger.log(details.exception, details.stack, 'FLUTTER_ERROR');
  };

  // Log errors not caught by Flutter (async errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    GlobalLogger.log(error, stack, 'GLOBAL_ASYNC_ERROR');
    return true;
  };

  // Generic error widget for build-time errors across every screen and component
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Scaffold(
        body: ZiroErrorView(
          error: details.exception,
          stackTrace: details.stack,
          title: 'A rendering error occurred',
          showStackTrace: kDebugMode,
        ),
      ),
    );
  };

  // Create container with global logger for automatic API error logging
  final container = ProviderContainer(
    observers: [GlobalLogger()],
  );

  await AppBootstrap.initialize(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ZiroFitApp(),
    ),
  );
}

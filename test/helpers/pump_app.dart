import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Extension on [WidgetTester] that wraps a widget in the standard
/// test shell: [ProviderScope] + [MaterialApp].
///
/// Usage:
/// ```dart
/// await tester.pumpApp(
///   const LoginScreen(),
///   overrides: [
///     authProvider.overrideWith((ref) => fakeAuthNotifier),
///   ],
/// );
/// ```
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: widget,
        ),
      ),
    );
  }
}

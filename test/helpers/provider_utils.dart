import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creates a [ProviderContainer] with optional [overrides] for testing.
///
/// The caller is responsible for calling [container.dispose] in `tearDown`.
///
/// Usage:
/// ```dart
/// late ProviderContainer container;
/// setUp(() {
///   container = createTestContainer(overrides: [...]);
/// });
/// tearDown(() => container.dispose());
/// ```
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  return ProviderContainer(overrides: overrides);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await AppBootstrap.initialize(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ZiroFitApp(),
    ),
  );
}

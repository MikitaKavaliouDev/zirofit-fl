import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SessionOverlayState { hidden, full, mini }

final sessionOverlayProvider = StateProvider<SessionOverlayState>((ref) => SessionOverlayState.hidden);
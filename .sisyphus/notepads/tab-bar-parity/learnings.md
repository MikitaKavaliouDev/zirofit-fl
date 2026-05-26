# Tab Bar Parity Fixes - Learnings

## Files Modified
- `lib/features/dashboard/widgets/ziro_shell.dart` — ZiroShell (ConsumerStatefulWidget)

## Changes Made

### Gap 1: Tab bar visible during full-screen workout
- **Before**: `bottomNavigationBar: ZiroTabBar(...)` unconditionally rendered
- **After**: `bottomNavigationBar: overlayState == SessionOverlayState.full ? null : ZiroTabBar(...)`
- The `sessionOverlayProvider` was already being watched (`overlayState`) in the build method
- `SessionOverlayState.full` corresponds to the full-screen workout overlay

### Gap 2: No tab reset on mode switch
- **Before**: No validation of tab index when mode changes
- **After**: Added `ref.listen(modeSwitchProvider, ...)` that checks if the current tab index is valid for the new mode's tab list; if out of bounds, navigates to Home (index 2)
- Uses `_tabsFor(location, next)` to compute the new tab list for the current location and new mode

### Gap 3: Double-tap pop-to-root
- **Verdict**: Already correctly implemented via `context.go(route)` in `onDoubleTapTab` for all tabs
- GoRouter's `context.go()` replaces the entire navigation stack for the ShellRoute branch
- The workout tab (client `/client/workout`) correctly skips navigation since it toggles an overlay, not a route

## Key Providers Used
- `modeSwitchProvider` (AppMode) — already imported
- `sessionOverlayProvider` (SessionOverlayState) — already imported
- Both used via `ref.watch` and `ref.listen` (no new imports needed)

## Verification
- `lsp_diagnostics`: No errors or warnings
- `flutter analyze`: Only pre-existing `prefer_const_constructors` info hints (5), no new issues

# Learnings: iOS Color Theme Audit Fix

## Files Changed
- `lib/core/theme/theme_colors.dart` — Primary color definitions (imported by 20+ widgets)
- `lib/core/theme/app_theme.dart` — AppTheme ThemeData constants + duplicate private _AppThemeColors class

## Key Changes
1. **Accent color**: Changed from emerald (`#10B981` light / `#34D399` dark) to static blue `#0083FF`
2. **Emerald color**: Added as separate named constant `emeraldColor = #10B981` for progress bars/success states
3. **Background colors**: All three background levels matched iOS hex values exactly:
   - Primary: `#F2F2F2` light / `#1C1C1E` dark
   - Secondary: `#FFFFFF` light / `#2C2C2E` dark  
   - Tertiary: `#E6E6E6` light / `#3A3A3C` dark
4. **textPrimary**: Changed from `#1F2937` to `#000000` in light mode
5. **New tokens**: Added `textSecondary` (#8E8E93 static), `cardBackground`, `contentBackground`
6. **AppTheme constants**: Updated `_primaryLight`, `_primaryDark`, `_surfaceDark`, `_backgroundDark` to match new values

## Architectural Note
- `theme_colors.dart` is the source of truth — all 20 widget files import it
- `app_theme.dart` has a private `_AppThemeColors` class that duplicates the same color getters (only imported by `app.dart`)
- Both were updated for consistency

## Pre-existing Issues (not introduced by this change)
- 3 x `undefined_identifier` errors in `lib/shared/widgets/ziro_sheet_header.dart` (context not available)
- Various info-level lints throughout the codebase

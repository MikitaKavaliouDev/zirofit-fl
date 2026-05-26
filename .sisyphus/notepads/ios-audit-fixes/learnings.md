# iOS Audit Fixes - Learnings

## Hardcoded Colors.blue → Theme Accent

**Files changed (6):**
- `buttons.dart` — PrimaryButton bg, SecondaryButton border+text → `Theme.of(context).colorScheme.primary`
- `common_ui.dart` — TabButton selected text, SelectedUnderline → `Theme.of(context).colorScheme.primary`
- `ziro_sheet_header.dart` — Cancel/Done text, trailing icon → `Theme.of(context).colorScheme.primary`
- `metric_card.dart` — default iconColor → `theme.colorScheme.primary`
- `custom_calendar_picker.dart` — selected/today bg+border → `themeColors.accent`
- `badge.dart` — info variant → `Theme.of(context).colorScheme.primary`

**Intentionally left as `Colors.blue`:**
- PremiumButton gradient (design choice: blue→purple)
- Avatar palette colors (ziro_avatar, custom_calendar_picker `_pickAvatarColor`)
- Doc comments only (rounded_corner, metric_card)

**Pattern:**
- Widgets with `context` access → `Theme.of(context).colorScheme.primary`
- Widgets already using `ThemeColors` (calendar) → `themeColors.accent`
- Badge `_color` method changed from `(Brightness)` to `(BuildContext)` to access theme

## Image.network → CachedAsyncImage

**Files changed (2):**
- `ziro_avatar.dart` — `Image.network` → `CachedAsyncImage(imageUrl:, errorWidget:)` (no more errorBuilder lambda)
- `ziro_header.dart` — same pattern

**Key differences from Image.network:**
- `imageUrl` is nullable (no `!` needed) vs `Image.network` requires non-null
- `errorWidget` is a `Widget?` (not a builder callback) vs `Image.network`'s `errorBuilder`
- No `errorBuilder` lambda needed — pass the fallback widget directly

## Notes
- `badge.dart` method signature was refactored: `_color(Brightness)` → `_color(BuildContext)`
- `ziro_sheet_header.dart` had 3 instances (Cancel, trailingIcon, Done) — all `Colors.blue` → theme
- `custom_calendar_picker.dart` already imported `cached_async_image.dart` (pre-existing)
- `ziro_avatar.dart` and `ziro_header.dart` now import `cached_async_image.dart`

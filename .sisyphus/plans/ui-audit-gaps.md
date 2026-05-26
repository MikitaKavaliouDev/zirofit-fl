# UI Parity Audit: iOS vs Flutter

**Generated:** 2026-05-25
**Sources:** `V:\Ziro-Fit\Ziro Fit\` (iOS Swift) vs `V:\zirofit-fl\` (Flutter Dart)
**Scope:** Colors, Tab Bar, Shared Widgets, Gradients

---

## 1. COLOR GAPS

### 1.1 Semantic Token Comparison

| Token | iOS Value | Flutter Value | Status |
|-------|-----------|---------------|--------|
| **accent** | `#0083FF` (static blue) | `#10B981` light / `#34D399` dark (emerald) | ❌ **WRONG COLOR** |
| **backgroundPrimary** | `#F2F2F2` light / `#1C1C1E` dark | `#FFFFFF` light / `#12121E` dark | ❌ **MISMATCH** |
| **backgroundSecondary** | `#FFFFFF` light / `#2C2C2E` dark | `#F3F4F6` light / `#1E1E2C` dark | ❌ **MISMATCH** |
| **backgroundTertiary** | `#E6E6E6` light / `#3A3A3C` dark | `#E5E7EB` light / `#2A2A3E` dark | ❌ **MISMATCH** |
| **textPrimary** | `#000000` light / `#FFFFFF` dark | `#1F2937` light / `#FFFFFF` dark | ❌ **MISMATCH** |
| **textSecondary** | System Gray (dynamic) | ❌ **MISSING — not defined** | ❌ **MISSING** |
| **cardBackground** | `#FFFFFF` light / `secondarySystemGroupedBackground` dark | ❌ **MISSING — uses `surfaceContainerHighest`** | ❌ **MISSING** |
| **contentBackground** | `systemGray6` light / `tertiarySystemGroupedBackground` dark | ❌ **MISSING — not defined** | ❌ **MISSING** |
| **background (asset)** | `Color("AppBackground")` from xcassets | ❌ **MISSING — not defined** | ❌ **MISSING** |

### 1.2 Critical Color Mismatches

#### A. ACCENT COLOR — COMPLETELY WRONG
```dart
// iOS accent:   #0083FF (blue, static light+dark)
// Flutter accent: #10B981 light / #34D399 dark (emerald)
```
iOS uses `#0083FF` (0.0, 0.5137, 1.0) as its theme accent — a saturated blue. Flutter uses emerald green (`#10B981`/`#34D399`) as its accent. **These are fundamentally different colors.** The entire app's primary interactive elements (selected tabs, buttons, links) will appear blue on iOS and green on Flutter.

#### B. iOS HAS A `.emerald` COLOR — SEPARATE FROM ACCENT
```swift
// GoalWidget.swift:93
static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)  // #10B981
```
iOS defines `Color.emerald = #10B981` (exactly Flutter's accent!) as a **distinct named color** used in gradient progress bars (`[.green, .emerald]`). This means:
- iOS accent = `#0083FF` (blue)
- iOS emerald = `#10B981` (green, used for progress/goals)
- **Flutter conflates these: accent = emerald = `#10B981`**

#### C. BACKGROUND VALUES DIFFERENT
iOS uses a light gray (`#F2F2F2`) for primary background in light mode, giving a subtle gray tint. Flutter uses pure white (`#FFFFFF`). This affects the entire visual feel.

#### D. TEXTPRIMARY NOT PURE BLACK
iOS uses pure black (`#000000`) for text in light mode. Flutter uses dark gray (`#1F2937`). This creates a subtle but perceptible difference in text rendering weight.

#### E. MISSING TOKENS
- **`textSecondary`**: iOS uses dynamic system gray for secondary text. Flutter hardcodes `Colors.grey` / `Colors.grey.shade*` throughout with no central token.
- **`cardBackground`**: iOS has a dedicated cardBackground color. Flutter uses `theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)` in MetricCard and various color references elsewhere.
- **`contentBackground`**: iOS has contentBackground for grouped content areas. Flutter has no equivalent.
- **`background` asset color**: iOS uses Color("AppBackground") from xcassets (can be customized per app icon). Flutter has no equivalent.

### 1.3 iOS System Color Coverage

| iOS System Color | Flutter Equivalent | Status |
|-----------------|-------------------|--------|
| `.blue` | `Colors.blue` | ✅ OK |
| `.purple` | `Colors.purple` | ✅ OK |
| `.green` | `Colors.green` | ✅ OK |
| `.orange` | `Colors.orange` | ✅ OK |
| `.red` | `Colors.red` | ✅ OK |
| `.pink` | `Colors.pink` | ✅ OK |
| `.indigo` | `Colors.indigo` | ✅ OK |
| `.teal` | `Colors.teal` | ✅ OK |
| `.cyan` | `Colors.cyan` | ✅ OK |
| `.yellow` | `Colors.yellow` | ✅ OK |
| `.gray` | `Colors.grey` (note spelling) | ⚠️ British/US spelling difference |
| `.white` | `Colors.white` | ✅ OK |
| `.black` | `Colors.black` | ✅ OK |
| `.clear` | `Colors.transparent` | ✅ OK |
| `.primary` | `Theme.of(context).colorScheme.primary` | ✅ OK |
| `.secondary` | `Theme.of(context).colorScheme.secondary` | ✅ OK |
| `.emerald` (#10B981) | `Color(0xFF10B981)` (used as accent!) | ⚠️ Exists but conflated with accent |
| `.map-green` (#32C86E) | ❌ **MISSING** | ❌ MISSING |

---

## 2. TAB BAR GAPS

### 2.1 Tab Configuration Comparison

| Aspect | iOS | Flutter | Status |
|--------|-----|---------|--------|
| **Trainer tabs** | Calendar, Programs, Home, Clients, More (5) | Calendar, Programs, Home, Clients, More + mode button (6) | ⚠️ **6th position mode button** |
| **Personal tabs** | Explore, Workouts, Home, Analytics, More (5) | Explore, Workouts, Home, Progress/Analytics, More + mode button (6) | ⚠️ **6th position mode button** |
| **Center tab** | Home (house.fill) — visually centered | Home (index 2) — not visually distinctive | ⚠️ **No special center treatment** |
| **Tab bar style** | `.ultraThinMaterial` + cornerRadius(40) | BackdropFilter blur + colored container + borderRadius(40) | ⚠️ **Different visual implementation** |
| **Tab bar border** | `.stroke(Color.theme.textPrimary.opacity(0.1), lineWidth: 1)` | ❌ **No border stroke** | ❌ **MISSING** |
| **Tab bar handle** | Capsule drag handle when custom mode enabled | ❌ **No drag handle** | ❌ **MISSING** |

### 2.2 Behavioral Gaps

#### GAP 1: Double-Tap Pop-to-Root

| Aspect | iOS | Flutter |
|--------|-----|---------|
| **Mechanism** | Posts `Notification.Name("PopToRoot")` via `NotificationCenter` | Calls `onDoubleTapTab` callback → `context.go(route)` |
| **Listener** | `PersonalHomeView` listens and resets `navigationId = UUID()` | No listener — just re-navigates to same route |
| **Effect** | **True navigation stack reset** — resets drill-down state | **Does NOT reset stack** — just calls GoRouter again |
| **Scope** | Only `PersonalHomeView` (.home tab) listens | All tabs get same treatment (go to route) |

**Fix needed:** Implement a proper pop-to-root mechanism that resets GoRouter's nested navigator stacks, not just calls `context.go()`.

#### GAP 2: Tab Bar Visibility During Workout

| Aspect | iOS | Flutter |
|--------|-----|---------|
| **Condition** | `!workoutManager.isSessionActive \|\| workoutManager.isMinimized` | **Tab bar always visible** |
| **Behavior** | Tab bar hidden when session is active AND not minimized (full-screen workout) | `ZiroTabBar` always rendered in `bottomNavigationBar` slot |
| **Override** | iOS `MainTabView.swift:75`: `if !workoutManager.isSessionActive \|\| workoutManager.isMinimized` | No equivalent condition in `ZiroShell.build()` |

**Fix needed:** Conditionally hide the `ZiroTabBar` when `sessionOverlayProvider` is in `full` state.

#### GAP 3: Mode Change → Tab Reset

| Aspect | iOS | Flutter |
|--------|-----|---------|
| **Mechanism** | `MainTabView.onChange(of: appState.currentMode)` | No equivalent listener |
| **Logic** | Check if `selectedTab` is in `AppTab.tabs(for: newMode)`. If not, reset to `.home`. | No tab validation on mode change |
| **Effect** | If switching from trainer (has "Calendar") to personal (no "Calendar"), tab resets to Home | **Tab stays on stale index** — could point to wrong screen |

**Fix needed:** In `ZiroShell`, listen to `modeSwitchProvider` changes and validate current selected index against new tab list.

#### GAP 4: Badge Mode Filtering

| Aspect | iOS | Flutter |
|--------|-----|---------|
| **Logic** | `unreadCount(for mode:)` filters by `notif.targetRole` matching current mode | Single `unreadCount` from `notificationsProvider` with no mode filter |
| **Detail** | iOS: personal mode shows targetRole="client" or nil; trainer mode shows targetRole="trainer" | Flutter: shows total unread count regardless of mode |
| **Effect** | Notifications badge only shows relevant notifications for current role | Badge shows ALL unread notifications, potentially confusing |

**Fix needed:** Update notifications provider to support mode-filtered badge counts.

#### GAP 5: Mode Selector — Tap vs Drag

| Aspect | iOS | Flutter |
|--------|-----|---------|
| **Mode access** | Tap tab bar → expand mode selector; OR long horizontal drag (40% screen width) → toggle directly | Tap 6th position mode button → expand mode selector; OR horizontal drag (40% screen width) → toggle directly |
| **Mode button** | No dedicated button — tap anywhere on background OR drag | 6th position `_ModeButton` with fitness_center/person icon + label |
| **"Custom Mode" toggle** | Toggle in MoreView: `isCustomModeEnabled` (default off, enables tap/drag on bar) | Mode button always visible, no "enable" toggle |
| **Handle** | Visible capsule handle when custom mode enabled | No handle visible |

**Fix needed:** The iOS tab bar does NOT have a 6th position mode button — it relies on tap/drag gestures on the tab bar itself. Flutter adds a 6th button, making the tab bar look different and potentially confusing users.

#### GAP 6: Tab Bar Background Material

| Aspect | iOS | Flutter |
|--------|-----|---------|
| **Background** | `.background(.ultraThinMaterial)` — dynamic blur that adapts to content behind it | `BackdropFilter(ImageFilter.blur(sigmaX:30, sigmaY:30))` over a static colored container |
| **Corner radius** | `.cornerRadius(40)` | `BorderRadius.vertical(top: Radius.circular(40))` |
| **Behavior** | iOS material automatically adapts to light/dark mode and background content | Static color `#1E1E2C` (dark) / `Colors.white` (light) with fixed blur — doesn't adapt to content |

**Fix needed:** Use system blur/material in Flutter that matches iOS ultraThinMaterial behavior.

---

## 3. WIDGET GAPS

### 3.1 Shared Widget Inventory

| Widget | File | Status | Issues |
|--------|------|--------|--------|
| **ZiroAvatar** | `lib/shared/widgets/ziro_avatar.dart` | ⚠️ **Uses `Image.network`** | No caching. Should use `CachedAsyncImage` instead |
| **CachedAsyncImage** | `lib/shared/widgets/cached_async_image.dart` | ✅ **Exists** | Correctly implemented with memory + disk cache |
| **PrimaryButton** | `lib/shared/widgets/buttons.dart` | ❌ **Hardcoded `Colors.blue`** (line 65) | Should use `Color.theme.accent` (#0083FF) |
| **SecondaryButton** | `lib/shared/widgets/buttons.dart` | ❌ **Hardcoded `Colors.blue`** (lines 145-146) | Should use accent color |
| **PremiumButton** | `lib/shared/widgets/buttons.dart` | ⚠️ **Gradient uses `Colors.blue, Colors.purple`** | Matches iOS blue→purple but uses system blue, not accent (#0083FF) |
| **Badge** | `lib/shared/widgets/badge.dart` | ✅ **Good structure** | Supports success/warning/error/info/neutral variants ✓ |
| **MetricCard** | `lib/shared/widgets/metric_card.dart` | ⚠️ **Default icon color `Colors.blue`** (line 74) | Should use accent color |
| **TabButton** | `lib/shared/widgets/common_ui.dart` | ❌ **Hardcoded `Colors.blue`** (lines 96, 121) | Should use theme accent |
| **TagView** | `lib/shared/widgets/common_ui.dart` | ✅ **OK** | Takes color as parameter |
| **ZiroHeader** | `lib/shared/widgets/ziro_header.dart` | ✅ **Good** | Proper theme color usage |
| **ZiroSheetHeader** | `lib/shared/widgets/ziro_sheet_header.dart` | ❌ **Hardcoded `Colors.blue`** (lines 122, 140, 154) | Should use accent |
| **ZiroDataView** | `lib/shared/widgets/ziro_data_view.dart` | ✅ **Good** | Loading/error/empty/data states |
| **DashboardSkeleton** | `lib/features/dashboard/widgets/dashboard_skeleton.dart` | ✅ **Good** | Mirrors iOS skeleton |
| **ListSkeleton** | `lib/shared/widgets/list_skeleton.dart` | ✅ **Good** | Shimmer-based |
| **CalendarSkeleton** | `lib/shared/widgets/calendar_skeleton.dart` | ✅ **Good** | Shimmer-based |
| **AnalyticsWidgetContainer** | `lib/features/progress/widgets/analytics_widget_container.dart` | ✅ **Good** | Mirrors iOS version |
| **CustomCalendarPicker** | `lib/shared/widgets/custom_calendar_picker.dart` | ❌ **Hardcoded `Colors.blue`** (lines 357, 361, 578) | Should use accent |

### 3.2 Missing Centralized Widgets

| Widget | iOS Location | Flutter Status |
|--------|-------------|----------------|
| **EmptyStateView** | No single file found (likely used inline) | ❌ **No centralized widget** — each screen defines its own `_buildEmptyState()` or `_EmptyState` class. 21+ files have duplicate empty state implementations. |
| **PremiumCard / MembershipCard** | `Views/Components/MembershipCardView.swift` | ❌ **No equivalent** in shared widgets |
| **GoalWidget** | `Views/Components/GoalWidget.swift` | ❌ **No equivalent** in shared widgets |
| **RecoveryWidget** | `Views/Components/RecoveryWidget.swift` | ❌ **No equivalent** in shared widgets |
| **DailyTargetCard** | `Views/Components/DailyTargetCard.swift` | ❌ **No equivalent** in shared widgets |

---

## 4. GRADIENT GAPS

### 4.1 iOS Gradient Usage Patterns

iOS uses `LinearGradient` extensively (60+ usages across 25+ files). Common patterns:

| Gradient Colors | Usage | iOS File |
|----------------|-------|----------|
| `[.blue, .purple]` | Tab bar glow, pro paywall, explore cards, trainer profile | Most common (6+ locations) |
| `[.purple, .blue]` | Program detail, timeline builder | ProgramDetailView, VisualTimelineBuilderView |
| `[.blue, .cyan]` | Daily target progress circle | DailyTargetCard |
| `[.green, .emerald]` | Goal progress bar | GoalWidget |
| `[.orange, .red]` | Personal home card | PersonalHomeView |
| `[.indigo, .purple]` | Workout session | WorkoutSessionView |
| `[black.opacity(0.8), black.opacity(0.0)]` | Image overlay fade | MarketplaceView |
| `[.blue.opacity(0.2), .clear]` | Chart fill | TrainerClientAnalyticsView |
| Multi-color (accent, purple, pink, orange, accent) | AI mode animation border | CustomTabBar (6-7 color rainbow) |
| `[.blue, .blue.opacity(0.7)]` | Trainer invitation header | TrainerInvitationDetailView |

### 4.2 Flutter Gradient Status

| Gradient | Flutter Status | Location |
|----------|---------------|----------|
| **blue→purple** | ⚠️ **Exists but inline** — `_activeGradient` in PremiumButton (line 233) and tab bar glow (line 423) | `buttons.dart`, `ziro_tab_bar.dart` |
| **emerald→blue→purple→pink** (4-color) | ✅ **Tab bar glow** (inline) | `ziro_tab_bar.dart` lines 421-428 |
| **Named gradient constants** | ❌ **NO named gradient constants anywhere** | No `class AppGradients` or equivalent |
| **Chart gradients** | ⚠️ **Parameterized** — passed via `LinearGradient gradient` / `LinearGradient fillGradient` | `interactive_line_chart.dart` |
| **green→emerald progress** | ❌ **MISSING** | No equivalent to GoalWidget gradient |
| **orange→red card** | ❌ **MISSING** | No equivalent to PersonalHomeView gradient |
| **indigo→purple** | ❌ **MISSING** | No equivalent to WorkoutSessionView gradient |
| **black fade overlay** | ❌ **MISSING** | No equivalent to MarketplaceView gradient |
| **blue→cyan progress circle** | ❌ **MISSING** | No equivalent to DailyTargetCard gradient |

### 4.3 Gradient Architecture Gap

**iOS:** Gradients are defined inline at usage sites (no centralized gradient constants).

**Flutter:** Same pattern — gradients are inline. No centralized gradient definitions. However, the sheer volume of iOS gradient usage (60+ instances) means Flutter should have equivalently styled gradients in corresponding screens. The key gap is not architectural but specific missing gradient patterns in screens that exist in Flutter but lack the gradient treatment.

---

## 5. ADDITIONAL FINDINGS

### 5.1 ZiroAvatar Uses Uncache Network Image
`ZiroAvatar` uses `Image.network` (line 101) which has no caching. A `CachedAsyncImage` widget already exists in the project but `ZiroAvatar` doesn't use it. Fix: Replace `Image.network` with `CachedAsyncImage`.

### 5.2 ZiroHeader Avatar Also Uncached
`ZiroHeader._buildAvatar()` (line 118) also uses `Image.network` directly. Should use `CachedAsyncImage`.

### 5.3 Hardcoded Colors.blue in 6 Widgets
18 instances of `Colors.blue` in shared widgets that should reference the theme accent color:
- `buttons.dart`: PrimaryButton (bg), SecondaryButton (border + text)
- `common_ui.dart`: TabButton (selected state), SelectedUnderline
- `ziro_sheet_header.dart`: 3 instances
- `ziro_avatar.dart`: _palette (intentional — avatar palette)
- `custom_calendar_picker.dart`: 3 instances
- `badge.dart`: info variant (debatable — semantic)
- `metric_card.dart`: default iconColor

### 5.4 Workout Active State and Tab Bar
iOS hides tab bar during full-screen workout (`isSessionActive && !isMinimized`). Flutter's `ZiroShell` always renders `ZiroTabBar` regardless of `sessionOverlayProvider` state. The iOS mini-player behavior uses `isMinimized`, while Flutter uses `SessionOverlayState.mini` — functionally similar but the tab bar visibility logic differs.

### 5.5 Mode-Specific Personal Icons
iOS personal mode swaps tab icons:
- Programs tab → sparkles icon (Explore)
- Clients tab → clock icon (Workouts)
- Analytics tab → chart.xyaxis.line icon (Analytics)

Flutter's `_clientTabs` uses different icons: `Icons.explore_outlined`, `Icons.fitness_center_outlined`, `Icons.trending_up_outlined`. These are semantically similar but visually different from iOS SF Symbols.

### 5.6 Unused Legacy Shells
`trainer_shell.dart` and `client_shell.dart` still exist and use plain Material `NavigationBar` (not `ZiroTabBar`). They are **superseded by `ZiroShell`** but remain in the codebase. They represent the OLD tab bar implementation with different tabs than iOS.

---

## 6. SUMMARY OF CRITICAL FIXES

| Priority | Gap | Impact | Effort |
|----------|-----|--------|--------|
| **P0** | Accent color is emerald (#10B981) instead of blue (#0083FF) | Entire app looks green instead of blue | Medium |
| **P0** | Tab bar always visible during workout | Full-screen workout has tab bar overlay | Small |
| **P1** | Missing `textSecondary`, `cardBackground`, `contentBackground` tokens | Inconsistent secondary text and card styling | Medium |
| **P1** | Background hex values differ from iOS | App background feels different | Small |
| **P1** | textPrimary uses #1F2937 instead of #000000 | Text looks less crisp than iOS | Small |
| **P1** | No tab reset on mode change | Can navigate to wrong screen after mode switch | Small |
| **P1** | Double-tap pop-to-root doesn't reset navigation stack | Drill-down state persists after re-tap | Medium |
| **P1** | 18+ hardcoded `Colors.blue` instead of accent | Some buttons/links use system blue, others use emerald — inconsistent | Medium |
| **P2** | 6th position mode button (iOS has none) | Tab bar has extra visual element | Small |
| **P2** | No centralized EmptyStateView | 21+ duplicate implementations | Medium |
| **P2** | No mode-filtered badge count | Badge shows irrelevant notifications | Small |
| **P2** | ZiroAvatar uses Image.network (no cache) | Image flicker on re-render | Small |
| **P2** | Tab bar border stroke missing | Slightly different visual treatment | Small |
| **P3** | No named gradient constants | Missing gradient treatments in various screens | Large |
| **P3** | Missing widget parity (GoalWidget, DailyTargetCard, etc.) | Feature-specific visual differences | Large |

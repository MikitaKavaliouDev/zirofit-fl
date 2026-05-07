import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Activity Attributes

/// The attributes and content state for workout Live Activities.
/// This must match the definitions in LiveActivityManager.swift.
struct WorkoutActivityAttributes: ActivityAttributes {
    /// Static metadata set when the activity is created.
    let activityId: String

    /// Dynamic content state that can be updated during the workout.
    struct ContentState: Codable, Hashable {
        /// Current exercise name displayed in the widget.
        var exerciseName: String
        /// Number of completed sets for the current exercise.
        var setCount: Int
        /// Total sets planned (0 if unknown).
        var totalSets: Int
        /// Remaining rest time in seconds (0 when not resting).
        var restSeconds: Int
        /// Total elapsed workout time in seconds.
        var elapsedSeconds: Int
    }
}

// MARK: - Live Activity Widget

/// Widget that renders the workout Live Activity in the Dynamic Island
/// and on the Lock Screen.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenWorkoutView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view — shown when user long-presses the Dynamic Island
                DynamicIslandExpandedContent {
                    expandedWorkoutContent(context: context)
                }
            } compactLeading: {
                // Compact leading view — shown on the left side of the island
                compactLeadingView(context: context)
            } compactTrailing: {
                // Compact trailing view — shown on the right side of the island
                compactTrailingView(context: context)
            } minimal: {
                // Minimal view — shown when another app's activity is also active
                minimalView(context: context)
            }
        }
    }

    // MARK: - Compact Views

    /// Compact leading: Shows a timer icon or rest indicator.
    /// - Shows a dumbbell icon during exercise.
    /// - Shows a timer icon with remaining time during rest.
    @ViewBuilder
    private func compactLeadingView(
        context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
        if context.state.restSeconds > 0 {
            Image(systemName: "timer")
                .foregroundColor(.orange)
                .font(.caption2)
        } else {
            Image(systemName: "dumbbell.fill")
                .foregroundColor(.green)
                .font(.caption2)
        }
    }

    /// Compact trailing: Shows the current exercise name or rest time.
    /// - During exercise: Shows abbreviated exercise name.
    /// - During rest: Shows remaining rest time (e.g., "0:45").
    @ViewBuilder
    private func compactTrailingView(
        context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
        if context.state.restSeconds > 0 {
            Text(formatRestTime(context.state.restSeconds))
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(.orange)
        } else if !context.state.exerciseName.isEmpty {
            Text(abbreviateExerciseName(context.state.exerciseName))
                .font(.caption2)
                .foregroundColor(.white)
        } else {
            Text("💪")
                .font(.caption2)
        }
    }

    /// Minimal view: Shown when the Dynamic Island is shared with another app.
    @ViewBuilder
    private func minimalView(
        context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
        if context.state.restSeconds > 0 {
            Text(formatRestTime(context.state.restSeconds))
                .font(.caption2)
                .monospacedDigit()
                .foregroundColor(.orange)
        } else {
            Image(systemName: "dumbbell.fill")
                .foregroundColor(.green)
                .font(.caption2)
        }
    }

    // MARK: - Expanded Content

    /// Expanded view shown when the user interacts with the Dynamic Island.
    /// Displays full workout details: exercise, sets, rest timer, elapsed time.
    @ViewBuilder
    private func expandedWorkoutContent(
        context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
        DynamicIslandExpandedRegion(.leading) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.green)
                Text("Workout")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }

        DynamicIslandExpandedRegion(.trailing) {
            Text(formatElapsedTime(context.state.elapsedSeconds))
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(.secondary)
        }

        DynamicIslandExpandedRegion(.bottom) {
            HStack {
                // Exercise and sets info
                VStack(alignment: .leading, spacing: 4) {
                    if !context.state.exerciseName.isEmpty {
                        Text(context.state.exerciseName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    HStack(spacing: 16) {
                        if context.state.setCount > 0 {
                            Label(
                                "\(context.state.setCount)/\(context.state.totalSets > 0 ? "\(context.state.totalSets)" : "–") sets",
                                systemImage: "chart.bar.fill"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        if context.state.restSeconds > 0 {
                            Label(
                                formatRestTime(context.state.restSeconds),
                                systemImage: "timer"
                            )
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Formatters

    /// Formats rest time as "MM:SS".
    private func formatRestTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Formats elapsed time as "H:MM:SS" or "MM:SS".
    private func formatElapsedTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// Abbreviates long exercise names for the compact Dynamic Island view.
    /// - "Bench Press" → "Bench"
    /// - "Barbell Back Squat" → "Squat"
    private func abbreviateExerciseName(_ name: String) -> String {
        let words = name.split(separator: " ")
        if words.count <= 2 {
            return name
        }
        // Use the last word for compound exercise names
        return String(words.last ?? "Ex")
    }
}

// MARK: - Lock Screen View

/// The view displayed on the Lock Screen when the workout Live Activity is active.
/// Shows exercise name, set count, rest timer, and elapsed time in a card layout.
struct LockScreenWorkoutView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.green)
                Text("Active Workout")
                    .font(.headline)
                Spacer()
                Text(formatElapsedTime(context.state.elapsedSeconds))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }

            // Exercise and stats
            if !context.state.exerciseName.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.exerciseName)
                            .font(.title3)
                            .fontWeight(.semibold)

                        if context.state.setCount > 0 {
                            Text("\(context.state.setCount) sets completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Rest timer badge
                    if context.state.restSeconds > 0 {
                        VStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text(formatRestTime(context.state.restSeconds))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Text("Let's go! 💪")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.3))
        .activitySystemActionForegroundColor(.white)
    }

    // MARK: - Formatters

    private func formatRestTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func formatElapsedTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

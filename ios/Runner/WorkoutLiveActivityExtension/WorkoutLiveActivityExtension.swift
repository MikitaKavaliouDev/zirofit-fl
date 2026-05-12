import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Workout Live Activity Widget

/// The widget configuration for the workout Live Activity.
///
/// Provides three presentation modes:
/// - **Dynamic Island** (compact leading/trailing + expanded + minimal)
/// - **Lock Screen / Banner** (full-width with workout details)
/// - **StandBy** (iOS 17+ full-screen mode)
struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            // Lock Screen / Banner UI — White background design
            WorkoutLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ---- Expanded Dynamic Island (long-press / swipe down) ----
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(state: context.state, mode: context.attributes.workoutMode)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // ---- Compact leading (right side of notch / pill) ----
                CompactLeadingView(state: context.state, mode: context.attributes.workoutMode)
            } compactTrailing: {
                // ---- Compact trailing (left side of notch / pill) ----
                CompactTrailingView(state: context.state)
            } minimal: {
                // ---- Minimal (when multiple Live Activities are active) ----
                MinimalView(state: context.state, mode: context.attributes.workoutMode)
            }
        }
    }
}

// MARK: - Lock Screen / Banner View (White Design)

/// Full-width Lock Screen and banner presentation for the workout Live Activity.
struct WorkoutLiveActivityView: View {
    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        ZStack {
            Color.white

            if context.state.isWorkoutComplete {
                // Workout complete state
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("Workout Complete")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    if let startDate = context.state.workoutStartDate {
                        Text(formattedDuration(from: startDate))
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
            } else if context.state.isResting, let restEndDate = context.state.restEndDate {
                // Rest timer state
                RestActiveView(
                    restEndDate: restEndDate,
                    totalRest: context.state.totalRestTime,
                    nextExerciseName: context.state.nextExerciseName,
                    isWhite: true
                )
                .padding(24)
            } else {
                // Active set state
                HStack(alignment: .bottom, spacing: 16) {
                    // LEFT COLUMN — Exercise info
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            if context.state.totalExercisesCount > 0 {
                                Text(
                                    "Exercise \(context.state.currentExerciseIndex) of \(context.state.totalExercisesCount)"
                                )
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            }

                            Text(context.state.currentExercise ?? "Workout")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)

                            if context.state.totalSetsCount > 0 {
                                Text(
                                    "Set \(context.state.currentSetIndex) of \(context.state.totalSetsCount)"
                                )
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            }
                        }

                        // Set progress bar
                        if context.state.totalSetsCount > 0 {
                            CapsuleProgressBar(
                                current: context.state.currentSetIndex,
                                total: context.state.totalSetsCount,
                                color: Color.blue,
                                isWhiteBackground: true
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // RIGHT COLUMN — Timer & controls
                    VStack(alignment: .trailing, spacing: 12) {
                        if let startDate = context.state.workoutStartDate {
                            FormattedTimerView(
                                startDate: startDate,
                                isPaused: context.state.isPaused,
                                isWhite: true
                            )
                            .frame(height: 36)
                        }

                        // Controls row
                        HStack(spacing: 8) {
                            Button(intent: PauseWorkoutIntent()) {
                                Image(systemName: context.state.isPaused ? "play.fill" : "pause")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(width: 60, height: 40)
                                    .background(Capsule().fill(Color(white: 0.9)))
                            }
                            .buttonStyle(.plain)

                            Button(intent: CompleteSetIntent()) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 40)
                                    .background(Capsule().fill(Color.green))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private func formattedDuration(from startDate: Date) -> String {
        let elapsed = Date().timeIntervalSince(startDate)
        let hours = Int(elapsed) / 3600
        let mins = (Int(elapsed) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Dynamic Island Expanded Views (Dark Design)

/// Leading region of the expanded Dynamic Island — shows exercise icon + name.
struct ExpandedLeadingView: View {
    let state: WorkoutAttributes.ContentState
    let mode: WorkoutAttributes.WorkoutMode

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode == .trainer ? "person.2.fill" : "dumbbell.fill")
                .font(.system(size: 14))
                .foregroundColor(mode == .trainer ? .purple : .blue)

            Text(state.currentExercise ?? "Workout")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.leading, 8)
    }
}

/// Trailing region of the expanded Dynamic Island — shows set progress.
struct ExpandedTrailingView: View {
    let state: WorkoutAttributes.ContentState

    var body: some View {
        if state.isResting, let restEndDate = state.restEndDate {
            Text(timerInterval: Date.now...restEndDate, countsDown: true)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
        } else {
            VStack(alignment: .trailing, spacing: 2) {
                Text("Set \(state.currentSetIndex)/\(state.totalSetsCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("\(Int(state.currentReps)) × \(formattedWeight(state.currentWeight))kg")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 8)
        }
    }

    private func formattedWeight(_ weight: Double) -> String {
        weight == floor(weight) ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
    }
}

/// Bottom region of the expanded Dynamic Island — primary content and controls.
struct ExpandedBottomView: View {
    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        if context.state.isWorkoutComplete {
            // Workout complete
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Workout Complete!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
        } else if context.state.isResting, let restEndDate = context.state.restEndDate {
            // Rest timer
            ExpandedRestView(
                restEndDate: restEndDate,
                totalRest: context.state.totalRestTime,
                nextExerciseName: context.state.nextExerciseName
            )
        } else {
            // Active set — full controls
            HStack(alignment: .bottom, spacing: 12) {
                // Left: exercise details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Ex \(context.state.currentExerciseIndex)/\(context.state.totalExercisesCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        if let setInfo = context.state.setInfo {
                            Text(setInfo)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }

                    if let startDate = context.state.workoutStartDate {
                        FormattedTimerView(
                            startDate: startDate,
                            isPaused: context.state.isPaused,
                            isWhite: false
                        )
                        .frame(height: 28)
                    }
                }

                Spacer()

                // Right: weight/reps steppers + complete button
                HStack(spacing: 6) {
                    StepperAdjustmentView(
                        value: context.state.currentWeight,
                        unit: "kg",
                        onDecrement: AdjustWeightIntent(weight: -2.5),
                        onIncrement: AdjustWeightIntent(weight: 2.5),
                        isWhite: false
                    )

                    StepperAdjustmentView(
                        value: context.state.currentReps,
                        unit: "reps",
                        onDecrement: AdjustRepsIntent(reps: -1),
                        onIncrement: AdjustRepsIntent(reps: 1),
                        isWhite: false
                    )

                    Button(intent: CompleteSetIntent()) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            let weightStr = formattedWeight(context.state.currentWeight)
                            Text("\(Int(context.state.currentReps))×\(weightStr)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(Capsule().fill(Color.green))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func formattedWeight(_ weight: Double) -> String {
        weight == floor(weight) ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
    }
}

// MARK: - Rest Timer View (Expanded Dynamic Island)

/// Shows the rest countdown timer with adjust/skip controls in the expanded Dynamic Island.
struct ExpandedRestView: View {
    let restEndDate: Date
    let totalRest: TimeInterval
    let nextExerciseName: String?

    var body: some View {
        HStack(spacing: 12) {
            // Left: next exercise name
            VStack(alignment: .leading, spacing: 2) {
                Text("Next:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(nextExerciseName ?? "—")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Center: countdown
            Text(timerInterval: Date.now...restEndDate, countsDown: true)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)

            // Right: skip button
            Button(intent: SkipRestIntent()) {
                Text("Skip")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 32)
                    .background(Capsule().fill(Color.orange))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Rest Active View (Lock Screen)

/// Full-width rest timer view used on the Lock Screen and banner.
struct RestActiveView: View {
    let restEndDate: Date
    let totalRest: TimeInterval
    let nextExerciseName: String?
    let isWhite: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // LEFT
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)

                    if let next = nextExerciseName {
                        Text("Next: \(next)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isWhite ? .black : .white)
                    }

                    // Adjust buttons
                    HStack(spacing: 8) {
                        Button(intent: AdjustRestIntent(seconds: -10)) {
                            Text("-10 s")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isWhite ? .black : .secondary)
                                .frame(width: 72, height: 40)
                                .background(
                                    Capsule().fill(
                                        isWhite ? Color(white: 0.9) : Color(white: 0.15)
                                    )
                                )
                        }
                        .buttonStyle(.plain)

                        Button(intent: AdjustRestIntent(seconds: 10)) {
                            Text("+10 s")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isWhite ? .black : .secondary)
                                .frame(width: 72, height: 40)
                                .background(
                                    Capsule().fill(
                                        isWhite ? Color(white: 0.9) : Color(white: 0.15)
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Progress bar
                ContinuousCapsuleProgress(
                    progress: max(
                        0.01,
                        min(1.0, restEndDate.timeIntervalSinceNow / totalRest)
                    ),
                    color: Color.orange,
                    isWhiteBackground: isWhite
                )
                .frame(height: 40)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // RIGHT
            VStack(alignment: .trailing, spacing: 12) {
                Text(timerInterval: Date.now...restEndDate, countsDown: true)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(isWhite ? .black : .white)

                Button(intent: SkipRestIntent()) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 72, height: 40)
                        .background(Capsule().fill(Color.orange))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Compact / Minimal Views

/// Compact leading view — shown on the left side of the Dynamic Island notch/pill.
struct CompactLeadingView: View {
    let state: WorkoutAttributes.ContentState
    let mode: WorkoutAttributes.WorkoutMode

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mode == .trainer ? "person.2.fill" : "dumbbell.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(mode == .trainer ? .purple : .blue)
            if let startDate = state.workoutStartDate {
                Text(timerInterval: startDate...Date.distantFuture, countsDown: false)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.leading, 4)
    }
}

/// Compact trailing view — shown on the right side of the Dynamic Island notch/pill.
struct CompactTrailingView: View {
    let state: WorkoutAttributes.ContentState

    var body: some View {
        if state.isResting, let restEndDate = state.restEndDate {
            Text(timerInterval: Date.now...restEndDate, countsDown: true)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
        } else {
            Text("\(state.currentSetIndex)/\(state.totalSetsCount)")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.blue)
        }
    }
}

/// Minimal view — shown when multiple Live Activities are active.
struct MinimalView: View {
    let state: WorkoutAttributes.ContentState
    let mode: WorkoutAttributes.WorkoutMode

    var body: some View {
        if state.isResting {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)
        } else {
            Text("\(state.currentSetIndex)")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Timer View

/// Displays formatted elapsed workout time (minutes only, per UX requirement).
struct FormattedTimerView: View {
    let startDate: Date
    let isPaused: Bool
    var isWhite: Bool = false

    var body: some View {
        Text(formattedSessionTime(from: startDate))
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundColor(isWhite ? .black : .white)
            .opacity(isPaused ? 0.5 : 1.0)
    }

    private func formattedSessionTime(from: Date) -> String {
        let elapsed = Date().timeIntervalSince(from)
        let hours = Int(elapsed) / 3600
        let mins = (Int(elapsed) % 3600) / 60

        if hours > 0 {
            return String(format: "%d:%02d", hours, mins)
        } else {
            return String(format: "%d", mins)
        }
    }
}

// MARK: - Reusable UI Components

/// A stepper control for adjusting weight or reps with +/- buttons.
struct StepperAdjustmentView: View {
    let value: Double
    let unit: String
    let onDecrement: any AppIntent
    let onIncrement: any AppIntent
    let isWhite: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button(intent: onDecrement) {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isWhite ? .black : .white)
                    .frame(width: 20, height: 32)
            }
            .buttonStyle(.plain)

            VStack(spacing: 0) {
                Text(
                    value == floor(value)
                        ? String(format: "%.0f", value)
                        : String(format: "%.1f", value)
                )
                .font(.system(size: 12, weight: .bold))
                Text(unit)
                    .font(.system(size: 7))
                    .opacity(0.6)
            }
            .foregroundColor(isWhite ? .black : .white)
            .frame(width: 32, height: 32)
            .background(isWhite ? Color(white: 0.95) : Color(white: 0.1))

            Button(intent: onIncrement) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isWhite ? .black : .white)
                    .frame(width: 20, height: 32)
            }
            .buttonStyle(.plain)
        }
        .background(
            Capsule().stroke(
                isWhite ? Color.black.opacity(0.1) : Color.white.opacity(0.1),
                lineWidth: 1
            )
        )
        .clipShape(Capsule())
    }
}

/// Segmented bar showing set progress (filled segments = completed sets).
struct CapsuleProgressBar: View {
    let current: Int
    let total: Int
    let color: Color
    let isWhiteBackground: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(1, total), id: \.self) { index in
                Capsule()
                    .fill(index < current ? color : inactiveColor)
                    .frame(height: 28)
            }
        }
    }

    private var inactiveColor: Color {
        isWhiteBackground ? color.opacity(0.1) : color.opacity(0.25)
    }
}

/// A single continuous capsule progress bar (used for rest timer).
struct ContinuousCapsuleProgress: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let isWhiteBackground: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(inactiveColor)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * CGFloat(progress) - 16))
                    .padding(8)
            }
        }
    }

    private var inactiveColor: Color {
        isWhiteBackground ? color.opacity(0.1) : color.opacity(0.25)
    }
}

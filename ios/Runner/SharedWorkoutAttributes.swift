import AppIntents
import Foundation
import WidgetKit

// MARK: - Shared Workout Live Activity Attributes
//
// This file must be added to BOTH targets in Xcode:
// 1. Runner (main app target) — used by LiveActivityManager.swift
// 2. WorkoutLiveActivityExtension (widget extension target) — used by the widget UI
//
// Add it via Xcode: Target Membership panel → check both targets.

#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - WorkoutAttributes

/// Attributes that define a workout Live Activity.
///
/// The `startTime` and `clientName` are static properties set when the
/// activity is first created and cannot be changed afterward. All dynamic
/// data lives in `ContentState` which is updated over the activity's lifecycle.
@available(iOS 16.2, *)
public struct WorkoutAttributes: ActivityAttributes {
    // MARK: - WorkoutMode

    public enum WorkoutMode: String, Codable, Sendable {
        case personal
        case trainer
    }

    // MARK: - ContentState

    /// The dynamic content state that can be updated during the activity.
    ///
    /// Maps directly to the Dart `LiveActivityData` class via method channel.
    /// All fields should be optional / have defaults so partial updates work.
    public struct ContentState: Codable, Hashable, Sendable {
        /// Workout start date — used for system-driven elapsed time timer
        public var workoutStartDate: Date?

        /// Name of the current exercise (e.g. "Bench Press")
        public var currentExercise: String?

        /// Index of current exercise (1-based for display: "Exercise 1 of 8")
        public var currentExerciseIndex: Int = 0

        /// Total number of exercises in the workout
        public var totalExercisesCount: Int = 0

        /// Index of the current set (1-based for display: "Set 1 of 4")
        public var currentSetIndex: Int = 0

        /// Total number of sets for the current exercise
        public var totalSetsCount: Int = 0

        /// Optional set description (e.g. "Warm-up", "Drop set")
        public var setInfo: String?

        /// Number of reps for the current set
        public var currentReps: Double = 0

        /// Weight being used for the current set (in kg)
        public var currentWeight: Double = 0

        /// Whether the user is currently resting between sets
        public var isResting: Bool = false

        /// When the rest period ends — used for system-driven countdown
        public var restEndDate: Date?

        /// Total rest time planned for this rest period (in seconds)
        public var totalRestTime: TimeInterval = 0

        /// Formatted rest time string (e.g. "01:30")
        public var restFormattedTime: String = "00:00"

        /// Name of the next exercise to be performed (shown during rest)
        public var nextExerciseName: String?

        /// Whether the entire workout is complete
        public var isWorkoutComplete: Bool = false

        /// Whether the current set is the last set of the current exercise
        public var isLastSet: Bool = false

        /// Whether the workout is currently paused
        public var isPaused: Bool = false

        // MARK: - Init

        public init(
            workoutStartDate: Date? = nil,
            currentExercise: String? = nil,
            currentExerciseIndex: Int = 0,
            totalExercisesCount: Int = 0,
            currentSetIndex: Int = 0,
            totalSetsCount: Int = 0,
            setInfo: String? = nil,
            currentReps: Double = 0,
            currentWeight: Double = 0,
            isResting: Bool = false,
            restEndDate: Date? = nil,
            totalRestTime: TimeInterval = 0,
            restFormattedTime: String = "00:00",
            nextExerciseName: String? = nil,
            isWorkoutComplete: Bool = false,
            isLastSet: Bool = false,
            isPaused: Bool = false
        ) {
            self.workoutStartDate = workoutStartDate
            self.currentExercise = currentExercise
            self.currentExerciseIndex = currentExerciseIndex
            self.totalExercisesCount = totalExercisesCount
            self.currentSetIndex = currentSetIndex
            self.totalSetsCount = totalSetsCount
            self.setInfo = setInfo
            self.currentReps = currentReps
            self.currentWeight = currentWeight
            self.isResting = isResting
            self.restEndDate = restEndDate
            self.totalRestTime = totalRestTime
            self.restFormattedTime = restFormattedTime
            self.nextExerciseName = nextExerciseName
            self.isWorkoutComplete = isWorkoutComplete
            self.isLastSet = isLastSet
            self.isPaused = isPaused
        }
    }

    // MARK: - Static Attributes (set once at creation)

    /// Client name shown in the activity (e.g. "John D." or "Personal Workout")
    public var clientName: String

    /// When the workout started — used for the overall session timer
    public var startTime: Date

    /// Whether this is a personal or trainer-led workout
    public var workoutMode: WorkoutMode

    // MARK: - Init

    public init(
        clientName: String,
        startTime: Date,
        workoutMode: WorkoutMode = .personal
    ) {
        self.clientName = clientName
        self.startTime = startTime
        self.workoutMode = workoutMode
    }
}

// MARK: - App Intents (for interactive Live Activity buttons)

/// Completes the current set and advances to the next.
public struct CompleteSetIntent: AppIntent {
    public static var title: LocalizedStringResource = "Complete Set"
    public static var isDiscoverable: Bool = false
    public static var action: (() async -> Void)?

    public init() {}

    public func perform() async throws -> some IntentResult {
        await Self.action?()
        return .result()
    }
}

/// Skips the remaining rest time and advances to the next set.
public struct SkipRestIntent: AppIntent {
    public static var title: LocalizedStringResource = "Skip Rest"
    public static var isDiscoverable: Bool = false
    public static var action: (() async -> Void)?

    public init() {}

    public func perform() async throws -> some IntentResult {
        await Self.action?()
        return .result()
    }
}

/// Finishes the entire workout.
public struct FinishWorkoutIntent: AppIntent {
    public static var title: LocalizedStringResource = "Finish Workout"
    public static var isDiscoverable: Bool = false
    public static var action: (() async -> Void)?

    public init() {}

    public func perform() async throws -> some IntentResult {
        await Self.action?()
        return .result()
    }
}

/// Adjusts the rest timer by a given number of seconds (positive or negative).
public struct AdjustRestIntent: AppIntent {
    public static var title: LocalizedStringResource = "Adjust Rest"
    public static var isDiscoverable: Bool = false
    public static var action: ((TimeInterval) async -> Void)?

    @Parameter(title: "Seconds")
    var seconds: TimeInterval

    public init() {}

    public init(seconds: TimeInterval) {
        self.seconds = seconds
    }

    public func perform() async throws -> some IntentResult {
        await Self.action?(seconds)
        return .result()
    }
}

/// Pauses or resumes the workout.
public struct PauseWorkoutIntent: AppIntent {
    public static var title: LocalizedStringResource = "Pause/Resume Workout"
    public static var isDiscoverable: Bool = false
    public static var action: (() async -> Void)?

    public init() {}

    public func perform() async throws -> some IntentResult {
        await Self.action?()
        return .result()
    }
}

/// Adjusts the rep count for the current set.
public struct AdjustRepsIntent: AppIntent {
    public static var title: LocalizedStringResource = "Adjust Reps"
    public static var isDiscoverable: Bool = false
    public static var action: ((Double) async -> Void)?

    @Parameter(title: "Reps")
    var reps: Double

    public init() {}

    public init(reps: Double) {
        self.reps = reps
    }

    public func perform() async throws -> some IntentResult {
        await Self.action?(reps)
        return .result()
    }
}

/// Adjusts the weight for the current set.
public struct AdjustWeightIntent: AppIntent {
    public static var title: LocalizedStringResource = "Adjust Weight"
    public static var isDiscoverable: Bool = false
    public static var action: ((Double) async -> Void)?

    @Parameter(title: "Weight")
    var weight: Double

    public init() {}

    public init(weight: Double) {
        self.weight = weight
    }

    public func perform() async throws -> some IntentResult {
        await Self.action?(weight)
        return .result()
    }
}

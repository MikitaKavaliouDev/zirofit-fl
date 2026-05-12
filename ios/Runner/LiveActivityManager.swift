import ActivityKit
import Flutter
import OSLog
import UIKit
import WidgetKit

/// Simple logger for Live Activity events
private let liveActivityLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.zirofit.fl",
    category: "LiveActivity"
)

/// Manages iOS Live Activities for workout tracking via ActivityKit.
///
/// This class bridges Flutter method channel calls to Apple's ActivityKit
/// framework, enabling Dynamic Island and Lock Screen updates during workouts.
///
/// ## Architecture
/// ```
/// Flutter (Dart)  →  MethodChannel  →  LiveActivityManager (Swift)  →  ActivityKit
/// ```
///
/// ## Supported Dynamic Island views
/// - **Compact leading**: Timer / workout mode icon
/// - **Compact trailing**: Rest countdown or set progress
/// - **Expanded (full)**: Exercise name, set info, elapsed time, controls
/// - **Minimal**: Pinpoint icon in crowded Dynamic Island
///
/// ## ContentState Fields (from Dart MethodChannel)
/// | Dart key               | Type      | Swift mapping            |
/// |------------------------|-----------|--------------------------|
/// | workoutStartDate       | int (ms)  | Date                     |
/// | currentExercise        | String?   | currentExercise          |
/// | currentExerciseIndex   | int       | currentExerciseIndex     |
/// | totalExercisesCount    | int       | totalExercisesCount      |
/// | currentSetIndex        | int       | currentSetIndex          |
/// | totalSetsCount         | int       | totalSetsCount           |
/// | setInfo                | String?   | setInfo                  |
/// | currentReps            | double    | currentReps              |
/// | currentWeight          | double    | currentWeight            |
/// | isResting              | bool      | isResting                |
/// | restSeconds            | int       | restEndDate (now + secs) |
/// | totalRestSeconds       | int       | totalRestTime            |
/// | restFormattedTime      | String    | restFormattedTime        |
/// | nextExerciseName       | String?   | nextExerciseName         |
/// | isWorkoutComplete      | bool      | isWorkoutComplete        |
/// | isLastSet              | bool      | isLastSet                |
/// | isPaused               | bool      | isPaused                 |
@available(iOS 16.2, *)
enum LiveActivityManager {
    // MARK: - Private State

    /// Reference to the currently active Live Activity, if any.
    private static var currentActivity: Activity<WorkoutAttributes>? {
        get {
            guard let activityId = UserDefaults.standard.string(forKey: "live_activity_id") else {
                return nil
            }
            return Activity<WorkoutAttributes>.activities.first { $0.id == activityId }
        }
        set {
            UserDefaults.standard.set(newValue?.id, forKey: "live_activity_id")
        }
    }

    // MARK: - Public API

    /// Checks whether Live Activities are supported on this device.
    /// - Returns: `true` on iOS 16.1+ devices with ActivityKit support.
    static func isSupported() -> Bool {
        if #available(iOS 16.2, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        } else {
            return false
        }
    }

    /// Starts a new Live Activity for the workout.
    ///
    /// The activity will appear in the Dynamic Island and on the Lock Screen.
    /// If an activity is already active, it will be updated instead.
    ///
    /// - Parameter data: Dictionary containing the initial workout data.
    ///   See `ContentState Fields` table above for supported keys.
    /// - Returns: `true` if the activity was successfully started/updated.
    @available(iOS 16.2, *)
    static func startActivity(data: [String: Any]) -> Bool {
        guard isSupported() else { return false }

        // If there's already an active activity, update it instead
        if let existing = currentActivity {
            return updateActivity(data: data, for: existing)
        }

        let clientName = data["clientName"] as? String ?? "Workout"
        let startTime = parseDate(from: data["startTime"])
        let workoutModeRaw = data["workoutMode"] as? String ?? "personal"
        let workoutMode = WorkoutAttributes.WorkoutMode(rawValue: workoutModeRaw) ?? .personal

        let attributes = WorkoutAttributes(
            clientName: clientName,
            startTime: startTime ?? Date(),
            workoutMode: workoutMode
        )

        let contentState = buildContentState(from: data)

        let content = ActivityContent<WorkoutAttributes.ContentState>(
            state: contentState,
            staleDate: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            liveActivityLogger.log("Started LiveActivity: \(activity.id)")
            return true
        } catch {
            liveActivityLogger.error("Failed to start LiveActivity: \(error.localizedDescription)")
            return false
        }
    }

    /// Updates the currently active Live Activity with new data.
    ///
    /// - Parameter data: Dictionary with updated workout data.
    ///   See `ContentState Fields` table above for supported keys.
    /// - Returns: `true` if the activity was successfully updated.
    @available(iOS 16.2, *)
    static func updateActivity(data: [String: Any]) -> Bool {
        guard let activity = currentActivity else {
            // No active activity; start a new one if we have minimal data
            return startActivity(data: data)
        }
        return updateActivity(data: data, for: activity)
    }

    /// Ends the Live Activity for the workout.
    ///
    /// The activity will be removed from the Dynamic Island and Lock Screen.
    /// On iOS 16.2+, a brief dismissal animation is shown.
    ///
    /// - Parameter data: Optional dictionary with summary data.
    ///   - `summary`: A text summary shown before dismissal (optional).
    /// - Returns: `true` if the activity was successfully ended.
    @available(iOS 16.2, *)
    static func endActivity(data: [String: Any]) -> Bool {
        guard let activity = currentActivity else { return false }

        // Build a final "complete" state
        var finalState = buildContentState(from: data)
        finalState.isWorkoutComplete = true

        // If a summary string was provided, put it in setInfo
        if let summary = data["summary"] as? String {
            finalState.setInfo = summary
        }

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
            UserDefaults.standard.removeObject(forKey: "live_activity_id")
            liveActivityLogger.log("Ended LiveActivity: \(activity.id)")
        }

        return true
    }

    // MARK: - Private Helpers

    /// Builds a `ContentState` from the method channel data dictionary.
    ///
    /// Handles type conversions:
    /// - `workoutStartDate`: milliseconds since epoch → `Date`
    /// - `restSeconds`: seconds → `restEndDate` (Date.now + seconds)
    /// - `totalRestSeconds`: seconds → `totalRestTime` (TimeInterval)
    @available(iOS 16.2, *)
    private static func buildContentState(from data: [String: Any]) -> WorkoutAttributes
        .ContentState
    {
        let workoutStartDate = parseDate(from: data["workoutStartDate"])
        let restSeconds = data["restSeconds"] as? Int ?? 0
        let totalRestSeconds = data["totalRestSeconds"] as? Int ?? 0

        // Convert rest seconds to an absolute end date for system-driven countdown
        let restEndDate: Date? = {
            if restSeconds > 0 {
                return Date().addingTimeInterval(TimeInterval(restSeconds))
            }
            return nil
        }()

        return WorkoutAttributes.ContentState(
            workoutStartDate: workoutStartDate,
            currentExercise: data["currentExercise"] as? String,
            currentExerciseIndex: data["currentExerciseIndex"] as? Int ?? 0,
            totalExercisesCount: data["totalExercisesCount"] as? Int ?? 0,
            currentSetIndex: data["currentSetIndex"] as? Int ?? 0,
            totalSetsCount: data["totalSetsCount"] as? Int ?? 0,
            setInfo: data["setInfo"] as? String,
            currentReps: data["currentReps"] as? Double ?? 0,
            currentWeight: data["currentWeight"] as? Double ?? 0,
            isResting: data["isResting"] as? Bool ?? false,
            restEndDate: restEndDate,
            totalRestTime: TimeInterval(totalRestSeconds),
            restFormattedTime: data["restFormattedTime"] as? String ?? "00:00",
            nextExerciseName: data["nextExerciseName"] as? String,
            isWorkoutComplete: data["isWorkoutComplete"] as? Bool ?? false,
            isLastSet: data["isLastSet"] as? Bool ?? false,
            isPaused: data["isPaused"] as? Bool ?? false
        )
    }

    /// Updates an existing activity with new content state.
    @available(iOS 16.2, *)
    private static func updateActivity(
        data: [String: Any],
        for activity: Activity<WorkoutAttributes>
    ) -> Bool {
        // Merge new data with existing state (partial update support)
        let existingState = activity.content.state
        let workoutStartDate = parseDate(from: data["workoutStartDate"])
            ?? existingState.workoutStartDate

        let restSeconds = data["restSeconds"] as? Int
        let totalRestSeconds = data["totalRestSeconds"] as? Int

        let restEndDate: Date? = {
            if let secs = restSeconds, secs > 0 {
                return Date().addingTimeInterval(TimeInterval(secs))
            }
            return data.keys.contains("restSeconds") ? nil : existingState.restEndDate
        }()

        let updatedState = WorkoutAttributes.ContentState(
            workoutStartDate: workoutStartDate,
            currentExercise: (data["currentExercise"] as? String) ?? existingState.currentExercise,
            currentExerciseIndex: (data["currentExerciseIndex"] as? Int)
                ?? existingState.currentExerciseIndex,
            totalExercisesCount: (data["totalExercisesCount"] as? Int)
                ?? existingState.totalExercisesCount,
            currentSetIndex: (data["currentSetIndex"] as? Int) ?? existingState.currentSetIndex,
            totalSetsCount: (data["totalSetsCount"] as? Int) ?? existingState.totalSetsCount,
            setInfo: (data["setInfo"] as? String) ?? existingState.setInfo,
            currentReps: (data["currentReps"] as? Double) ?? existingState.currentReps,
            currentWeight: (data["currentWeight"] as? Double) ?? existingState.currentWeight,
            isResting: (data["isResting"] as? Bool) ?? existingState.isResting,
            restEndDate: restEndDate,
            totalRestTime: TimeInterval(
                totalRestSeconds ?? Int(existingState.totalRestTime)
            ),
            restFormattedTime: (data["restFormattedTime"] as? String)
                ?? existingState.restFormattedTime,
            nextExerciseName: (data["nextExerciseName"] as? String)
                ?? existingState.nextExerciseName,
            isWorkoutComplete: (data["isWorkoutComplete"] as? Bool)
                ?? existingState.isWorkoutComplete,
            isLastSet: (data["isLastSet"] as? Bool) ?? existingState.isLastSet,
            isPaused: (data["isPaused"] as? Bool) ?? existingState.isPaused
        )

        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
            liveActivityLogger.log("Updated LiveActivity: \(activity.id)")
        }

        return true
    }

    /// Parses a date from method channel arguments.
    ///
    /// Accepts:
    /// - `Int` / `Double`: milliseconds since Unix epoch
    /// - `nil`: returns `nil`
    private static func parseDate(from value: Any?) -> Date? {
        guard let value = value else { return nil }
        if let ms = value as? Int {
            return Date(timeIntervalSince1970: TimeInterval(ms) / 1000.0)
        }
        if let ms = value as? Double {
            return Date(timeIntervalSince1970: ms / 1000.0)
        }
        return nil
    }
}

// MARK: - Flutter Method Channel Handler

/// Handles incoming method calls from Flutter's MethodChannel
/// and delegates to LiveActivityManager.
class LiveActivityPluginHandler: NSObject {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported":
            if #available(iOS 16.2, *) {
                result(LiveActivityManager.isSupported())
            } else {
                result(false)
            }

        case "startActivity":
            guard let args = call.arguments as? [String: Any] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Expected dictionary arguments",
                        details: nil
                    ))
                return
            }
            if #available(iOS 16.2, *) {
                result(LiveActivityManager.startActivity(data: args))
            } else {
                result(
                    FlutterError(
                        code: "UNSUPPORTED",
                        message: "Live Activities require iOS 16.2+",
                        details: nil
                    ))
            }

        case "updateActivity":
            guard let args = call.arguments as? [String: Any] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Expected dictionary arguments",
                        details: nil
                    ))
                return
            }
            if #available(iOS 16.2, *) {
                result(LiveActivityManager.updateActivity(data: args))
            } else {
                result(
                    FlutterError(
                        code: "UNSUPPORTED",
                        message: "Live Activities require iOS 16.2+",
                        details: nil
                    ))
            }

        case "endActivity":
            let args = call.arguments as? [String: Any] ?? [:]
            if #available(iOS 16.2, *) {
                result(LiveActivityManager.endActivity(data: args))
            } else {
                result(
                    FlutterError(
                        code: "UNSUPPORTED",
                        message: "Live Activities require iOS 16.2+",
                        details: nil
                    ))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

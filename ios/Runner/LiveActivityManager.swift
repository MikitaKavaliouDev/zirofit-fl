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
/// - **Compact leading**: Timer / rest indicator icon
/// - **Compact trailing**: Current exercise name
/// - **Expanded (minimal)**: Exercise name + rest countdown
/// - **Expanded (full)**: Full workout details including sets and elapsed time
@available(iOS 16.2, *)
enum LiveActivityManager {
    // MARK: - Activity Attributes

    /// The attributes that define the workout Live Activity.
    /// This is the type passed to ActivityKit when requesting a new activity.
    struct WorkoutAttributes: ActivityAttributes {
        /// Content state that can be updated during the activity's lifecycle.
        public struct ContentState: Codable, Hashable {
            /// Current exercise name (e.g., "Bench Press")
            var exerciseName: String
            /// Number of completed sets for current exercise
            var setCount: Int
            /// Total sets planned (0 if unknown)
            var totalSets: Int
            /// Remaining rest time in seconds (0 when not resting)
            var restSeconds: Int
            /// Total elapsed workout time in seconds
            var elapsedSeconds: Int
        }

        /// Static metadata set when the activity is created
        var activityId: String
    }

    // MARK: - Private State

    /// Reference to the currently active Live Activity, if any.
    private static var currentActivity: Activity<WorkoutAttributes>? {
        // Find an existing activity with matching ID, or return nil
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
    /// - Parameter data: Dictionary containing the initial workout data
    ///   - `activityId`: Unique session identifier
    ///   - `exerciseName`: Name of the first exercise (optional)
    ///   - `restSeconds`: Initial rest time (optional)
    ///   - `elapsedSeconds`: Elapsed workout time in seconds
    /// - Returns: `true` if the activity was successfully started/updated.
    @available(iOS 16.2, *)
    static func startActivity(data: [String: Any]) -> Bool {
        guard isSupported() else { return false }

        // If there's already an active activity, update it instead
        if let existing = currentActivity {
            return updateActivity(data: data, for: existing)
        }

        let activityId = data["activityId"] as? String ?? UUID().uuidString
        let exerciseName = data["exerciseName"] as? String ?? ""
        let setCount = data["setCount"] as? Int ?? 0
        let totalSets = data["totalSets"] as? Int ?? 0
        let restSeconds = data["restSeconds"] as? Int ?? 0
        let elapsedSeconds = data["elapsedSeconds"] as? Int ?? 0

        let attributes = WorkoutAttributes(activityId: activityId)
        let contentState = WorkoutAttributes.ContentState(
            exerciseName: exerciseName,
            setCount: setCount,
            totalSets: totalSets,
            restSeconds: restSeconds,
            elapsedSeconds: elapsedSeconds
        )

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
            liveActivityLogger.log("Started: \(activity.id)")
            return true
        } catch {
            liveActivityLogger.log("Failed to start: \(error.localizedDescription)")
            return false
        }
    }

    /// Updates the currently active Live Activity with new data.
    ///
    /// - Parameter data: Dictionary with updated workout data
    ///   - `exerciseName`, `setCount`, `totalSets`, `restSeconds`, `elapsedSeconds`
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
    /// - Parameter data: Optional dictionary with summary data
    ///   - `summary`: A text summary shown before dismissal
    /// - Returns: `true` if the activity was successfully ended.
    @available(iOS 16.2, *)
    static func endActivity(data: [String: Any]) -> Bool {
        guard let activity = currentActivity else { return false }

        let summary = data["summary"] as? String ?? "Workout Complete"

        let finalState = WorkoutAttributes.ContentState(
            exerciseName: summary,
            setCount: 0,
            totalSets: 0,
            restSeconds: 0,
            elapsedSeconds: 0
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
            UserDefaults.standard.removeObject(forKey: "live_activity_id")
            liveActivityLogger.log("Ended: \(activity.id)")
        }

        return true
    }

    // MARK: - Private Helpers

    /// Updates an existing activity with new content state.
    @available(iOS 16.2, *)
    private static func updateActivity(
        data: [String: Any],
        for activity: Activity<WorkoutAttributes>
    ) -> Bool {
        let exerciseName = data["exerciseName"] as? String ?? ""
        let setCount = data["setCount"] as? Int ?? 0
        let totalSets = data["totalSets"] as? Int ?? 0
        let restSeconds = data["restSeconds"] as? Int ?? 0
        let elapsedSeconds = data["elapsedSeconds"] as? Int ?? 0

        let updatedState = WorkoutAttributes.ContentState(
            exerciseName: exerciseName,
            setCount: setCount,
            totalSets: totalSets,
            restSeconds: restSeconds,
            elapsedSeconds: elapsedSeconds
        )

        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
            liveActivityLogger.log("Updated: \(activity.id)")
        }

        return true
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
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected dictionary arguments",
                    details: nil
                ))
                return
            }
            if #available(iOS 16.2, *) {
                result(LiveActivityManager.startActivity(data: args))
            } else {
                result(FlutterError(
                    code: "UNSUPPORTED",
                    message: "Live Activities require iOS 16.2+",
                    details: nil
                ))
            }

        case "updateActivity":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected dictionary arguments",
                    details: nil
                ))
                return
            }
            if #available(iOS 16.2, *) {
                result(LiveActivityManager.updateActivity(data: args))
            } else {
                result(FlutterError(
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
                result(FlutterError(
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

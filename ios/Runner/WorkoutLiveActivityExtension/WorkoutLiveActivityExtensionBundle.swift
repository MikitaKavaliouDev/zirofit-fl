import SwiftUI
import WidgetKit

/// Entry point for the Workout Live Activity widget extension.
///
/// This bundle is loaded by iOS when a Live Activity is active.
/// It registers the `WorkoutLiveActivityWidget` which renders the
/// Dynamic Island and Lock Screen UI for active workouts.
///
/// ## Target Membership
/// This file belongs to the `WorkoutLiveActivityExtension` target only.
/// Do NOT add it to the `Runner` main app target.
@main
struct WorkoutLiveActivityExtensionBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}

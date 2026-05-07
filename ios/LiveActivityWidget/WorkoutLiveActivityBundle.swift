import SwiftUI
import WidgetKit

/// Main entry point for the Workout Live Activity widget.
///
/// This widget bundle is registered in the Widget Extension's Info.plist
/// under `NSExtensionPrincipalClass`.
@main
struct WorkoutLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
    }
}

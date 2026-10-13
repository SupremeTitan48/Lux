import SwiftUI

@main
struct LuxWatchApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            TodayView().environment(model)
        }
    }
}

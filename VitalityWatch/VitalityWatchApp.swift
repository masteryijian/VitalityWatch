import SwiftUI

@main
struct VitalityWatchApp: App {
    @StateObject private var model = HealthModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}

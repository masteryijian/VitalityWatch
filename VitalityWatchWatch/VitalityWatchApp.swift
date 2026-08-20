import SwiftUI

@main
struct VitalityWatch_Watch_App: App {
    @StateObject private var model = HealthModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: HealthModel

    var body: some View {
        TabView {
            TodayView()
            SleepView()
            TrendsView()
            InsightsView()
        }
        .tabViewStyle(.verticalPage)
        .task {
            if model.service.hasRequestedAuthorization() {
                await model.load()
            } else {
                await model.authorizeAndLoad()
            }
        }
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
    }
}

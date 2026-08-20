import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: HealthModel

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("今日", systemImage: "heart.fill") }
            TrendsView()
                .tabItem { Label("趋势", systemImage: "chart.line.uptrend.xyaxis") }
            LogView()
                .tabItem { Label("记录", systemImage: "square.and.pencil") }
        }
        .task {
            if model.service.hasRequestedAuthorization() {
                await model.load()
            } else {
                await model.authorizeAndLoad()
            }
        }
        .overlay {
            if model.isLoading {
                ProgressView("加载健康数据…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("健康数据权限", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.clearError() } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

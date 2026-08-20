import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: HealthModel

    var body: some View {
        TabView {
            if model.snapshot.hasData || model.isLoading {
                RecoveryPage(score: model.readiness ?? 0)

                MetricValuePage(
                    icon: "heart",
                    title: "心率",
                    value: Fmt.bpm(model.snapshot.heartRate),
                    unit: "bpm",
                    footnote: restingFootnote,
                    color: .pink
                )

                MetricValuePage(
                    icon: "waveform.path.ecg",
                    title: "HRV",
                    value: Fmt.hrv(model.snapshot.hrv),
                    unit: "ms",
                    footnote: hrvFootnote,
                    color: .mint
                )

                MetricValuePage(
                    icon: "drop",
                    title: "血氧",
                    value: Fmt.percent(model.snapshot.spo2),
                    unit: "SpO₂",
                    footnote: nil,
                    color: .cyan
                )

                MetricValuePage(
                    icon: "thermometer",
                    title: "腕温",
                    value: Fmt.celsius(model.snapshot.wristTemperature),
                    unit: "",
                    footnote: "Series 8+ 才有腕温传感器\nSeries 7 此页无数据属正常",
                    color: .orange
                )

                SleepPage(sleep: model.snapshot.sleep)

                MetricValuePage(
                    icon: "figure.walk",
                    title: "步数",
                    value: Fmt.count(model.snapshot.steps),
                    unit: "步",
                    footnote: energyFootnote,
                    color: .green
                )

                MetricValuePage(
                    icon: "hourglass",
                    title: "生物年龄",
                    value: bioAgeValue,
                    unit: "岁",
                    footnote: "估算值，非医学结论",
                    color: .purple
                )

                TrendPage(title: "HRV 趋势", color: .mint, points: hrvPoints)
                TrendPage(title: "静息心率趋势", color: .pink, points: restingHRPoints)
                InsightsPage(insights: model.insights)
            } else {
                NoDataPage(authorization: model.authorization)
            }
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
        .alert("健康数据", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.clearError() } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var restingFootnote: String? {
        guard let baseline = model.snapshot.restingHeartRateBaseline else { return nil }
        return "静息心率基线 \(Fmt.bpm(baseline)) bpm"
    }

    private var hrvFootnote: String? {
        guard let baseline = model.snapshot.hrvBaseline else { return nil }
        return "14 天基线 \(Fmt.hrv(baseline)) ms"
    }

    private var temperatureFootnote: String? {
        guard let baseline = model.snapshot.temperatureBaseline else { return nil }
        return "睡眠腕温基线 \(Fmt.celsius(baseline))"
    }

    private var energyFootnote: String? {
        guard let energy = model.snapshot.activeEnergy else { return nil }
        return "活动能量 \(Fmt.kcal(energy))"
    }

    private var bioAgeValue: String {
        model.bioAge.map { String(format: "%.1f", $0) } ?? "–"
    }

    private var hrvPoints: [(Date, Double)] {
        model.days.compactMap { day in
            guard let value = day.hrv else { return nil }
            return (day.date, value)
        }
    }

    private var restingHRPoints: [(Date, Double)] {
        model.days.compactMap { day in
            guard let value = day.restingHR else { return nil }
            return (day.date, value)
        }
    }
}

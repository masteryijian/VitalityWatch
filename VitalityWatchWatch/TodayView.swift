import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: HealthModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("今日")
                    .font(.headline)

                WatchScoreRing(score: model.readiness ?? 0, label: "恢复分")

                if let bioAge = model.bioAge {
                    Label("生物年龄 \(String(format: "%.1f", bioAge)) 岁", systemImage: "hourglass")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    WatchMetric(label: "心率", value: Fmt.bpm(model.snapshot.heartRate), icon: "heart")
                    WatchMetric(label: "HRV", value: Fmt.hrv(model.snapshot.hrv), icon: "waveform.path.ecg")
                    WatchMetric(label: "血氧", value: Fmt.percent(model.snapshot.spo2), icon: "drop")
                    WatchMetric(label: "腕温", value: Fmt.celsius(model.snapshot.wristTemperature), icon: "thermometer")
                    WatchMetric(label: "睡眠", value: Fmt.hours(model.snapshot.sleep?.total), icon: "bed.double")
                    WatchMetric(label: "步数", value: Fmt.count(model.snapshot.steps), icon: "figure.walk")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct WatchScoreRing: View {
    let score: Double
    let label: String

    private var fraction: Double { min(1, max(0, score / 100)) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .green],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(score.rounded()))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text(label)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 110)
        }
    }
}

struct WatchMetric: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject private var model: HealthModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("趋势")
                    .font(.headline)

                Text("HRV (ms)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                hrvChart
                    .frame(height: 90)

                Text("静息心率 (bpm)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                rhrChart
                    .frame(height: 90)

                if let momentum = model.momentum {
                    Text("Momentum: \(String(format: "%+.1f 分/天", momentum.slopePerDay))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var hrvChart: some View {
        let points = model.days.compactMap { day -> (Date, Double)? in
            guard let v = day.hrv else { return nil }
            return (day.date, v)
        }
        return Chart(points, id: \.0) { point in
            LineMark(
                x: .value("日期", point.0, unit: .day),
                y: .value("HRV", point.1)
            )
            .foregroundStyle(.mint)
            .interpolationMethod(.catmullRom)
        }
    }

    private var rhrChart: some View {
        let points = model.days.compactMap { day -> (Date, Double)? in
            guard let v = day.restingHR else { return nil }
            return (day.date, v)
        }
        return Chart(points, id: \.0) { point in
            LineMark(
                x: .value("日期", point.0, unit: .day),
                y: .value("静息心率", point.1)
            )
            .foregroundStyle(.pink)
            .interpolationMethod(.catmullRom)
        }
    }
}

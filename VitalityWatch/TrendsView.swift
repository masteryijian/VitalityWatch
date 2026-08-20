import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject private var model: HealthModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    momentumCard
                    chartCard(title: "HRV (ms)", color: .mint) { $0.hrv }
                    chartCard(title: "静息心率 (bpm)", color: .pink) { $0.restingHR }
                    stepsCard
                }
                .padding()
            }
            .navigationTitle("趋势")
        }
    }

    private var momentumCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("长期指标").font(.headline)
            if let bioAge = model.bioAge {
                HStack {
                    Label("生物年龄", systemImage: "hourglass")
                    Spacer()
                    Text(String(format: "%.1f 岁", bioAge)).bold()
                }
            }
            if let momentum = model.momentum {
                HStack {
                    Label("Momentum", systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    Text(String(format: "%+.2f 分/天", momentum.slopePerDay)).bold()
                }
                Text("实验性指数：按 30 天斜率折算约 \(String(format: "%+.1f", momentum.lifeDays30)) 个“生命日”。仅作趋势参考，非医学结论。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }

    private func chartCard(title: String, color: Color, value: @escaping (DaySnapshot) -> Double?) -> some View {
        let points = model.days.compactMap { day -> (Date, Double)? in
            guard let v = value(day) else { return nil }
            return (day.date, v)
        }
        return VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if points.isEmpty {
                Text("暂无数据").font(.caption).foregroundStyle(.secondary)
            } else {
                Chart(points, id: \.0) { point in
                    LineMark(
                        x: .value("日期", point.0, unit: .day),
                        y: .value("值", point.1)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 140)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }

    private var stepsCard: some View {
        let points = model.days.compactMap { day -> (Date, Double)? in
            guard let steps = day.steps else { return nil }
            return (day.date, steps)
        }
        return VStack(alignment: .leading, spacing: 8) {
            Text("步数").font(.headline)
            if points.isEmpty {
                Text("暂无数据").font(.caption).foregroundStyle(.secondary)
            } else {
                Chart(points, id: \.0) { point in
                    BarMark(
                        x: .value("日期", point.0, unit: .day),
                        y: .value("步数", point.1)
                    )
                    .foregroundStyle(.teal)
                }
                .frame(height: 140)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }
}

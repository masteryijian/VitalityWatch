import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var model: HealthModel

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ScoreRing(score: model.readiness ?? 0, title: "恢复分")
                    metricGrid
                    bioAgeCard
                    insightsCard
                }
                .padding()
            }
            .navigationTitle("今日")
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MetricCell(icon: "heart", label: "心率", value: Fmt.bpm(model.snapshot.heartRate), unit: "bpm")
            MetricCell(icon: "waveform.path.ecg", label: "HRV", value: Fmt.hrv(model.snapshot.hrv), unit: "ms")
            MetricCell(icon: "drop", label: "血氧", value: Fmt.percent(model.snapshot.spo2), unit: "")
            MetricCell(icon: "thermometer", label: "腕温", value: Fmt.celsius(model.snapshot.wristTemperature), unit: "")
            MetricCell(icon: "bed.double", label: "睡眠", value: Fmt.hours(model.snapshot.sleep?.total), unit: "")
            MetricCell(icon: "figure.walk", label: "步数", value: Fmt.count(model.snapshot.steps), unit: "步")
            MetricCell(icon: "flame", label: "活动能量", value: Fmt.kcal(model.snapshot.activeEnergy), unit: "")
            MetricCell(icon: "lungs", label: "呼吸", value: Fmt.bpm(model.snapshot.respiratoryRate), unit: "次/分")
        }
    }

    private var bioAgeCard: some View {
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

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("早筛提示").font(.headline)
            ForEach(model.insights) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: insight.iconName)
                        .foregroundStyle(insight.severity == .warning ? .orange : .green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title).font(.subheadline.weight(.semibold))
                        Text(insight.message).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Text("基于个人基线的偏差检测，不构成医疗诊断。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct MetricCell: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.tint)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

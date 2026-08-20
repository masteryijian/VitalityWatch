import SwiftUI
import Charts

// MARK: - 恢复分（一页一个展示区）

struct RecoveryPage: View {
    let score: Double

    var body: some View {
        VStack(spacing: 6) {
            WatchScoreRing(score: score, label: "恢复分")
            Text("HRV · 静息心率 · 睡眠\n腕温 · 呼吸率 加权评分")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 4)
    }
}

struct MetricValuePage: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let footnote: String?
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let footnote {
                Text(footnote)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 4)
    }
}

// MARK: - 睡眠

struct SleepPage: View {
    let sleep: SleepSummary?

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bed.double")
                .font(.system(size: 20))
                .foregroundStyle(.indigo)
            Text("睡眠")
                .font(.headline)

            if let sleep, sleep.total > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(Fmt.hours(sleep.total))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.55)
                    Text("评分 \(Fmt.score(Scores.sleepScore(sleep)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 4) {
                    SleepBar(label: "深睡", duration: sleep.deep, total: sleep.total, color: .indigo)
                    SleepBar(label: "REM", duration: sleep.rem, total: sleep.total, color: .teal)
                    SleepBar(label: "浅睡", duration: sleep.core, total: sleep.total, color: .mint)
                    SleepBar(label: "清醒", duration: sleep.awake, total: sleep.total, color: .gray)
                }
                .padding(.top, 2)
            } else {
                Text("暂无睡眠数据\n请佩戴手表睡觉后查看")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 6)
    }
}

struct SleepBar: View {
    let label: String
    let duration: TimeInterval
    let total: TimeInterval
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                Spacer()
                Text(Fmt.hours(duration))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * CGFloat(duration / total)))
                }
            }
            .frame(height: 7)
        }
        .padding(.vertical, 1)
    }
}

// MARK: - 趋势（一页一张图）

struct TrendPage: View {
    let title: String
    let color: Color
    let points: [(Date, Double)]

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
            if points.isEmpty {
                Text("暂无数据")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                Chart(points, id: \.0) { point in
                    LineMark(
                        x: .value("日期", point.0, unit: .day),
                        y: .value("值", point.1)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - 早筛提示

struct InsightsPage: View {
    let insights: [Insight]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("早筛提示")
                    .font(.headline)
                Text("基于个人基线的偏差检测，非医学诊断。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 2) {
                        Label(insight.title, systemImage: insight.iconName)
                            .font(.caption)
                            .foregroundStyle(insight.severity == .warning ? .orange : .green)
                        Text(insight.message)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 恢复分圆环

struct WatchScoreRing: View {
    let score: Double
    let label: String

    private var fraction: Double { min(1, max(0, score / 100)) }

    var body: some View {
        VStack(spacing: 2) {
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

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

// MARK: - 无数据时的引导页

struct NoDataPage: View {
    let authorization: HealthAuthorization

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("还没有健康数据")
                    .font(.headline)

                authStatusRow

                switch authorization {
                case .notDetermined:
                    Text("首次打开 App 时，手表会弹出「允许 Vitality 访问健康数据」的提示，请点「允许」。如果一直没有弹出，说明安装的可能是旧版本或签名不完整，请在 Xcode 中重新运行安装。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                case .denied:
                    Text("健康权限被拒绝。请删除本 App 后重新安装，再打开一次并点「允许」。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                case .authorized:
                    Text("健康权限已授权，但还没有读到数据。请确认 iPhone 的「健康」App 有心率记录，且手表佩戴正常。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Text("按顺序检查：")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                guideRow(number: "1", text: "允许健康权限（见上方提示）")
                guideRow(number: "2", text: "佩戴手表，心率会自动记录到健康 App")
                guideRow(number: "3", text: "打开 iPhone 的「健康」App → 浏览 → 心率，确认有心率数据")
                guideRow(number: "4", text: "血氧需在手表的「血氧」App 主动测量过才有数据")
                guideRow(number: "5", text: "Series 7 无腕温传感器，腕温页永远显示 –，属正常")
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var authStatusRow: some View {
        HStack(spacing: 4) {
            Image(systemName: authIcon)
                .font(.system(size: 11))
                .foregroundStyle(authColor)
            Text("健康权限：\(authText)")
                .font(.system(size: 11))
                .foregroundStyle(authColor)
        }
    }

    private var authText: String {
        switch authorization {
        case .notDetermined: return "未请求"
        case .denied: return "已拒绝"
        case .authorized: return "已授权"
        }
    }

    private var authIcon: String {
        switch authorization {
        case .notDetermined: return "questionmark.circle"
        case .denied: return "lock.fill"
        case .authorized: return "checkmark.circle.fill"
        }
    }

    private var authColor: Color {
        switch authorization {
        case .notDetermined: return .orange
        case .denied: return .red
        case .authorized: return .green
        }
    }

    private func guideRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text(number)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.tint)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

import SwiftUI

struct SleepView: View {
    @EnvironmentObject private var model: HealthModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("睡眠")
                    .font(.headline)

                if let sleep = model.snapshot.sleep, sleep.total > 0 {
                    Text(Fmt.hours(sleep.total))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("睡眠评分 \(Fmt.score(Scores.sleepScore(sleep)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SleepBar(label: "深睡", duration: sleep.deep, total: sleep.total, color: .indigo)
                    SleepBar(label: "REM", duration: sleep.rem, total: sleep.total, color: .teal)
                    SleepBar(label: "浅睡", duration: sleep.core, total: sleep.total, color: .mint)
                    SleepBar(label: "清醒", duration: sleep.awake, total: sleep.total, color: .gray)
                } else {
                    Text("暂无睡眠数据\n请佩戴手表睡觉后查看")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct SleepBar: View {
    let label: String
    let duration: TimeInterval
    let total: TimeInterval
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption2)
                Spacer()
                Text(Fmt.hours(duration))
                    .font(.caption2)
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
            .frame(height: 8)
        }
        .padding(.vertical, 2)
    }
}

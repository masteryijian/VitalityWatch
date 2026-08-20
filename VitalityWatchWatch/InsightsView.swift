import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var model: HealthModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("早筛提示")
                    .font(.headline)
                Text("基于个人基线的偏差检测，非医学诊断。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(model.insights) { insight in
                    VStack(alignment: .leading, spacing: 2) {
                        Label(insight.title, systemImage: insight.iconName)
                            .font(.caption)
                            .foregroundStyle(insight.severity == .warning ? .orange : .green)
                        Text(insight.message)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

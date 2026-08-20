import SwiftUI

struct ScoreRing: View {
    let score: Double
    let title: String

    private var fraction: Double { min(1, max(0, score / 100)) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .green],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(score.rounded()))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
        }
        .frame(maxWidth: .infinity)
    }
}

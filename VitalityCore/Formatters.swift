import Foundation

public enum Fmt {
    public static func bpm(_ value: Double?) -> String { value.map { "\(Int($0.rounded()))" } ?? "–" }
    public static func hrv(_ value: Double?) -> String { value.map { String(format: "%.0f", $0) } ?? "–" }
    // HealthKit 中血氧/体脂等 percent 类型的值是 0–1 的小数（0.97 = 97%），显示时乘 100。
    public static func percent(_ value: Double?) -> String { value.map { String(format: "%.0f%%", $0 * 100) } ?? "–" }
    public static func celsius(_ value: Double?) -> String { value.map { String(format: "%.1f°C", $0) } ?? "–" }
    public static func count(_ value: Double?) -> String { value.map { "\(Int($0.rounded()))" } ?? "–" }
    public static func kcal(_ value: Double?) -> String { value.map { "\(Int($0.rounded())) kcal" } ?? "–" }
    public static func score(_ value: Double?) -> String { value.map { "\(Int($0.rounded()))" } ?? "–" }

    public static func distance(_ value: Double?) -> String {
        guard let value else { return "–" }
        return value >= 1000 ? String(format: "%.2f km", value / 1000) : "\(Int(value)) m"
    }

    public static func hours(_ value: TimeInterval?) -> String {
        guard let value, value > 0 else { return "–" }
        return String(format: "%.1f h", value / 3600)
    }
}

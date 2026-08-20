import Foundation

public enum Insights {
    public static func forToday(snapshot: HealthSnapshot) -> [Insight] {
        var result: [Insight] = []

        if let hrv = snapshot.hrv, let baseline = snapshot.hrvBaseline, baseline > 0 {
            let ratio = hrv / baseline
            if ratio < 0.85 {
                result.append(Insight(
                    title: "HRV 偏低",
                    message: "今日 HRV 较 14 天基线下降超过 15%，可能与压力或恢复不足有关。",
                    severity: .warning
                ))
            } else if ratio > 1.15 {
                result.append(Insight(
                    title: "HRV 高于基线",
                    message: "今日 HRV 明显高于基线，恢复状态良好。",
                    severity: .info
                ))
            }
        }

        if let rhr = snapshot.restingHeartRate, let baseline = snapshot.restingHeartRateBaseline, baseline > 0 {
            if rhr > baseline * 1.08 {
                result.append(Insight(
                    title: "静息心率升高",
                    message: "静息心率较基线上升超过 8%，建议今天降低训练强度。",
                    severity: .warning
                ))
            }
        }

        if let temp = snapshot.wristTemperature, let baseline = snapshot.temperatureBaseline {
            let deviation = abs(temp - baseline)
            if deviation > 0.5 {
                result.append(Insight(
                    title: "腕温偏离基线",
                    message: "腕温偏离 \(String(format: "%.1f", deviation))°C，可能反映身体状态变化。",
                    severity: .warning
                ))
            }
        }

        if let sleep = snapshot.sleep, sleep.total > 0 {
            if sleep.total < 6 * 3600 {
                result.append(Insight(
                    title: "睡眠不足",
                    message: "总睡眠不足 6 小时，今日恢复分会受影响。",
                    severity: .warning
                ))
            }
            let deepREM = sleep.deep + sleep.rem
            if deepREM > 0 && deepREM < sleep.total * 0.2 {
                result.append(Insight(
                    title: "深睡/REM 偏少",
                    message: "深睡与 REM 合计占比低于 20%，睡眠质量可能偏低。",
                    severity: .info
                ))
            }
        }

        if let steps = snapshot.steps, steps < 3000 {
            result.append(Insight(
                title: "活动量偏低",
                message: "今日步数不足 3000 步。",
                severity: .info
            ))
        }

        if result.isEmpty {
            result.append(Insight(
                title: "未发现明显异常",
                message: "今日各项指标都在个人基线范围内。",
                severity: .info
            ))
        }
        return result
    }
}

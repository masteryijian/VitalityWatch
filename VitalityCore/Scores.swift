import Foundation

public enum Scores {
    public static func sleepScore(_ sleep: SleepSummary?) -> Double {
        guard let sleep, sleep.total > 0 else { return 50 }
        let target: TimeInterval = 7.5 * 3600
        let durationComponent = 100 - min(100, abs(sleep.total - target) / (target * 0.5) * 100)
        let deepREM = sleep.deep + sleep.rem
        let deepREMComponent = deepREM > 0 ? min(100, deepREM / (sleep.total * 0.35) * 100) : 0
        let efficiencyComponent = sleep.sleepEfficiency * 100
        return max(0, min(100, durationComponent * 0.5 + deepREMComponent * 0.3 + efficiencyComponent * 0.2))
    }

    public static func readiness(snapshot: HealthSnapshot) -> Double {
        readiness(
            hrv: snapshot.hrv, hrvBaseline: snapshot.hrvBaseline,
            restingHR: snapshot.restingHeartRate, restingHRBaseline: snapshot.restingHeartRateBaseline,
            sleep: snapshot.sleep,
            temperature: snapshot.wristTemperature, temperatureBaseline: snapshot.temperatureBaseline,
            respiratoryRate: snapshot.respiratoryRate, respiratoryBaseline: snapshot.respiratoryBaseline
        )
    }

    public static func readiness(day: DaySnapshot, baseline: DayBaseline) -> Double {
        readiness(
            hrv: day.hrv, hrvBaseline: baseline.hrv,
            restingHR: day.restingHR, restingHRBaseline: baseline.restingHR,
            sleep: day.sleep,
            temperature: day.wristTemp, temperatureBaseline: baseline.wristTemp,
            respiratoryRate: day.respiratoryRate, respiratoryBaseline: baseline.respiratoryRate
        )
    }

    public static func readiness(
        hrv: Double?, hrvBaseline: Double?,
        restingHR: Double?, restingHRBaseline: Double?,
        sleep: SleepSummary?,
        temperature: Double?, temperatureBaseline: Double?,
        respiratoryRate: Double?, respiratoryBaseline: Double?
    ) -> Double {
        let hrvComponent = normalizedComponent(value: hrv, baseline: hrvBaseline, higherIsBetter: true, sensitivity: 0.25)
        let rhrComponent = normalizedComponent(value: restingHR, baseline: restingHRBaseline, higherIsBetter: false, sensitivity: 0.06)
        let sleepComponent = sleepScore(sleep)
        let tempComponent: Double
        if let temperature, let temperatureBaseline {
            let deviation = abs(temperature - temperatureBaseline)
            tempComponent = max(0, 100 - min(100, deviation / 0.6 * 100))
        } else {
            tempComponent = 50
        }
        let respComponent = normalizedComponent(value: respiratoryRate, baseline: respiratoryBaseline, higherIsBetter: false, sensitivity: 0.12)

        let score = hrvComponent * 0.30
            + rhrComponent * 0.25
            + sleepComponent * 0.30
            + tempComponent * 0.10
            + respComponent * 0.05
        return max(0, min(100, score))
    }

    private static func normalizedComponent(value: Double?, baseline: Double?, higherIsBetter: Bool, sensitivity: Double) -> Double {
        guard let value, let baseline, baseline > 0 else { return 50 }
        let ratio = value / baseline
        let raw = higherIsBetter ? (ratio - 1) / sensitivity : (1 - ratio) / sensitivity
        return max(0, min(100, 50 + raw * 50))
    }

    public static func biologicalAge(chronologicalAge: Double, snapshot: HealthSnapshot) -> Double {
        var age = chronologicalAge
        if let restingHR = snapshot.restingHeartRate {
            age -= (62 - restingHR) * 0.12
        }
        if let hrv = snapshot.hrv {
            if hrv >= 40 {
                age -= max(0, min(8, (hrv - 40) / 10 * 0.8))
            } else {
                age += 2
            }
        }
        if let respiratoryRate = snapshot.respiratoryRate {
            age += (respiratoryRate - 14) * 0.25
        }
        if let sleep = snapshot.sleep, sleep.total > 0 {
            age += abs(sleep.hours - 7.5) * 0.3
        }
        if let vo2Max = snapshot.vo2Max {
            age -= (vo2Max - 35) * 0.15
        }
        return max(chronologicalAge - 20, min(chronologicalAge + 20, age))
    }

    public struct DayBaseline {
        public var hrv: Double?
        public var restingHR: Double?
        public var wristTemp: Double?
        public var respiratoryRate: Double?

        public init(hrv: Double? = nil, restingHR: Double? = nil, wristTemp: Double? = nil, respiratoryRate: Double? = nil) {
            self.hrv = hrv
            self.restingHR = restingHR
            self.wristTemp = wristTemp
            self.respiratoryRate = respiratoryRate
        }
    }

    public static func baseline(from days: [DaySnapshot]) -> DayBaseline {
        DayBaseline(
            hrv: mean(days.compactMap(\.hrv)),
            restingHR: mean(days.compactMap(\.restingHR)),
            wristTemp: mean(days.compactMap(\.wristTemp)),
            respiratoryRate: mean(days.compactMap(\.respiratoryRate))
        )
    }

    private static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    public struct Momentum {
        public let slopePerDay: Double
        public let lifeDays30: Double

        public init(slopePerDay: Double, lifeDays30: Double) {
            self.slopePerDay = slopePerDay
            self.lifeDays30 = lifeDays30
        }
    }

    public static func momentum(from readinessValues: [Double]) -> Momentum {
        let values = readinessValues
        guard values.count >= 3 else { return Momentum(slopePerDay: 0, lifeDays30: 0) }
        let n = Double(values.count)
        var meanX = 0.0
        var meanY = 0.0
        for index in 0..<values.count {
            meanX += Double(index)
            meanY += values[index]
        }
        meanX /= n
        meanY /= n

        var numerator = 0.0
        var denominator = 0.0
        for index in 0..<values.count {
            let dx = Double(index) - meanX
            let dy = values[index] - meanY
            numerator += dx * dy
            denominator += dx * dx
        }
        let slope = denominator > 0 ? numerator / denominator : 0
        return Momentum(slopePerDay: slope, lifeDays30: slope * 30 * 0.35)
    }
}

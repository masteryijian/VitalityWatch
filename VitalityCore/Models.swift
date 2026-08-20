import Foundation

public struct HealthSnapshot: Equatable {
    public var heartRate: Double?
    public var restingHeartRate: Double?
    public var restingHeartRateBaseline: Double?
    public var hrv: Double?
    public var hrvBaseline: Double?
    public var spo2: Double?
    public var wristTemperature: Double?
    public var temperatureBaseline: Double?
    public var respiratoryRate: Double?
    public var respiratoryBaseline: Double?
    public var steps: Double?
    public var activeEnergy: Double?
    public var distanceMeters: Double?
    public var vo2Max: Double?
    public var sleep: SleepSummary?
    public var systolic: Double?
    public var diastolic: Double?

    public init() {}

    public var hasData: Bool {
        heartRate != nil || restingHeartRate != nil || hrv != nil || spo2 != nil ||
        wristTemperature != nil || respiratoryRate != nil || steps != nil ||
        activeEnergy != nil || (sleep?.total ?? 0) > 0
    }
}

public struct SleepSummary: Equatable {
    public var total: TimeInterval
    public var deep: TimeInterval
    public var rem: TimeInterval
    public var core: TimeInterval
    public var awake: TimeInterval
    public var startDate: Date?
    public var endDate: Date?

    public init(total: TimeInterval = 0, deep: TimeInterval = 0, rem: TimeInterval = 0,
                core: TimeInterval = 0, awake: TimeInterval = 0,
                startDate: Date? = nil, endDate: Date? = nil) {
        self.total = total
        self.deep = deep
        self.rem = rem
        self.core = core
        self.awake = awake
        self.startDate = startDate
        self.endDate = endDate
    }

    public var sleepEfficiency: Double {
        let inBed = total + awake
        return inBed > 0 ? total / inBed : 0
    }

    public var hours: Double { total / 3600 }
}

public struct DaySnapshot: Identifiable, Equatable {
    public var id: Date { date }
    public let date: Date
    public var hrv: Double?
    public var restingHR: Double?
    public var wristTemp: Double?
    public var respiratoryRate: Double?
    public var steps: Double?
    public var activeEnergy: Double?
    public var sleep: SleepSummary?
    public var readiness: Double?

    public init(date: Date, hrv: Double? = nil, restingHR: Double? = nil, wristTemp: Double? = nil,
                respiratoryRate: Double? = nil, steps: Double? = nil, activeEnergy: Double? = nil,
                sleep: SleepSummary? = nil, readiness: Double? = nil) {
        self.date = date
        self.hrv = hrv
        self.restingHR = restingHR
        self.wristTemp = wristTemp
        self.respiratoryRate = respiratoryRate
        self.steps = steps
        self.activeEnergy = activeEnergy
        self.sleep = sleep
        self.readiness = readiness
    }
}

public struct Insight: Identifiable, Equatable {
    public enum Severity: String {
        case info
        case warning
    }

    public let id = UUID()
    public let title: String
    public let message: String
    public let severity: Severity

    public init(title: String, message: String, severity: Severity) {
        self.title = title
        self.message = message
        self.severity = severity
    }

    public var iconName: String {
        severity == .warning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
    }

    public static func == (lhs: Insight, rhs: Insight) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message && lhs.severity == rhs.severity
    }
}

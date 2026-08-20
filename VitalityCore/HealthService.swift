import Foundation
import HealthKit

public enum HealthError: LocalizedError {
    case notAvailable
    case denied
    case saveFailed
    case typeUnavailable

    public var errorDescription: String? {
        switch self {
        case .notAvailable: return "此设备不支持 HealthKit。"
        case .denied: return "健康数据权限被拒绝，请在健康 App 中允许访问。"
        case .saveFailed: return "写入健康数据失败。"
        case .typeUnavailable: return "健康数据类型不可用。"
        }
    }
}

public enum HealthAuthorization: Equatable {
    case notDetermined
    case denied
    case authorized
}

public final class HealthService {
    public static let shared = HealthService()

    private let store = HKHealthStore()

    public init() {}

    public var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    public static let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        let quantityIDs: [HKQuantityTypeIdentifier] = [
            .heartRate, .restingHeartRate, .heartRateVariabilitySDNN,
            .oxygenSaturation, .appleSleepingWristTemperature, .respiratoryRate,
            .stepCount, .activeEnergyBurned, .distanceWalkingRunning,
            .vo2Max, .bloodPressureSystolic, .bloodPressureDiastolic
        ]
        for id in quantityIDs {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()

    public static let writeTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()
        let ids: [HKQuantityTypeIdentifier] = [.dietaryEnergyConsumed, .bodyMass, .bodyFatPercentage]
        for id in ids {
            if let type = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(type)
            }
        }
        return types
    }()

    public func requestAuthorization() async throws {
        guard isAvailable else { throw HealthError.notAvailable }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.requestAuthorization(toShare: Self.writeTypes, read: Self.readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthError.denied)
                }
            }
        }
    }

    public func hasRequestedAuthorization() -> Bool {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return false }
        return store.authorizationStatus(for: heartRateType) != .notDetermined
    }

    public var authorization: HealthAuthorization {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return .notDetermined }
        switch store.authorizationStatus(for: heartRateType) {
        case .sharingAuthorized: return .authorized
        case .sharingDenied: return .denied
        default: return .notDetermined
        }
    }

    // MARK: - Snapshot

    public func loadSnapshot() async -> HealthSnapshot {
        var s = HealthSnapshot()
        let now = Date()
        let last24h = now.addingTimeInterval(-24 * 3600)
        guard let start14d = Calendar.current.date(byAdding: .day, value: -14, to: now) else { return s }

        s.heartRate = await latestQuantity(.heartRate, unit: Self.bpm, since: 1)
        s.restingHeartRate = await averageQuantity(.restingHeartRate, unit: Self.bpm, start: last24h, end: now)
        s.restingHeartRateBaseline = await averageQuantity(.restingHeartRate, unit: Self.bpm, start: start14d, end: now)
        s.hrv = await averageQuantity(.heartRateVariabilitySDNN, unit: Self.hrvUnit, start: last24h, end: now)
        s.hrvBaseline = await averageQuantity(.heartRateVariabilitySDNN, unit: Self.hrvUnit, start: start14d, end: now)
        s.spo2 = await averageQuantity(.oxygenSaturation, unit: .percent(), start: last24h, end: now)
        s.wristTemperature = await averageQuantity(.appleSleepingWristTemperature, unit: .degreeCelsius(), start: last24h, end: now)
        s.temperatureBaseline = await averageQuantity(.appleSleepingWristTemperature, unit: .degreeCelsius(), start: start14d, end: now)
        s.respiratoryRate = await averageQuantity(.respiratoryRate, unit: Self.bpm, start: last24h, end: now)
        s.respiratoryBaseline = await averageQuantity(.respiratoryRate, unit: Self.bpm, start: start14d, end: now)
        s.steps = await sumQuantity(.stepCount, unit: .count(), start: last24h, end: now)
        s.activeEnergy = await sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), start: last24h, end: now)
        s.distanceMeters = await sumQuantity(.distanceWalkingRunning, unit: .meter(), start: last24h, end: now)
        s.vo2Max = await latestQuantity(.vo2Max, unit: Self.vo2Unit, since: 90)
        s.sleep = await sleepSummary(over: Self.lastNightInterval)
        s.systolic = await latestQuantity(.bloodPressureSystolic, unit: .millimeterOfMercury(), since: 30)
        s.diastolic = await latestQuantity(.bloodPressureDiastolic, unit: .millimeterOfMercury(), since: 30)
        return s
    }

    // MARK: - Daily trends

    public func dailySnapshots(days: Int) async -> [DaySnapshot] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        var result: [DaySnapshot] = []

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .day, value: -offset, to: todayStart),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }

            var day = DaySnapshot(date: start)
            async let hrv = averageQuantity(.heartRateVariabilitySDNN, unit: Self.hrvUnit, start: start, end: end)
            async let rhr = averageQuantity(.restingHeartRate, unit: Self.bpm, start: start, end: end)
            async let temp = averageQuantity(.appleSleepingWristTemperature, unit: .degreeCelsius(), start: start, end: end)
            async let resp = averageQuantity(.respiratoryRate, unit: Self.bpm, start: start, end: end)
            async let steps = sumQuantity(.stepCount, unit: .count(), start: start, end: end)
            async let energy = sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)

            day.hrv = await hrv
            day.restingHR = await rhr
            day.wristTemp = await temp
            day.respiratoryRate = await resp
            day.steps = await steps
            day.activeEnergy = await energy

            let nightStart = start.addingTimeInterval(-6 * 3600)
            let nightEnd = end.addingTimeInterval(6 * 3600)
            day.sleep = await sleepSummary(over: DateInterval(start: nightStart, end: nightEnd))
            result.append(day)
        }
        return result
    }

    // MARK: - Writing

    public func writeQuantity(_ id: HKQuantityTypeIdentifier, value: Double, unit: HKUnit, at date: Date = Date()) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { throw HealthError.typeUnavailable }
        let sample = HKQuantitySample(
            type: type,
            quantity: HKQuantity(unit: unit, doubleValue: value),
            start: date,
            end: date
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.save(sample) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthError.saveFailed)
                }
            }
        }
    }

    // MARK: - Export

    public static func csv(from days: [DaySnapshot]) -> String {
        var lines = ["date,hrv_ms,resting_hr_bpm,wrist_temp_c,respiratory_rate,steps,active_kcal,sleep_hours,deep_hours,rem_hours,readiness"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for day in days {
            let sleep = day.sleep
            let dateString = formatter.string(from: day.date)
            let hrvString = day.hrv.map { String(format: "%.1f", $0) } ?? ""
            let rhrString = day.restingHR.map { String(format: "%.1f", $0) } ?? ""
            let tempString = day.wristTemp.map { String(format: "%.2f", $0) } ?? ""
            let respString = day.respiratoryRate.map { String(format: "%.1f", $0) } ?? ""
            let stepsString = day.steps.map { String(format: "%.0f", $0) } ?? ""
            let energyString = day.activeEnergy.map { String(format: "%.0f", $0) } ?? ""
            let sleepString = sleep.map { String(format: "%.2f", $0.hours) } ?? ""
            let deepString = sleep.map { String(format: "%.2f", $0.deep / 3600) } ?? ""
            let remString = sleep.map { String(format: "%.2f", $0.rem / 3600) } ?? ""
            let readinessString = day.readiness.map { String(format: "%.0f", $0) } ?? ""
            let fields = [
                dateString, hrvString, rhrString, tempString, respString,
                stepsString, energyString, sleepString, deepString, remString, readinessString
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Private queries

    private func latestQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, since days: Int) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func averageQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate, .strictEndDate])
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, _ in
                continuation.resume(returning: statistics?.averageQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func sumQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [.strictStartDate, .strictEndDate])
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func sleepSummary(over interval: DateInterval) async -> SleepSummary {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return SleepSummary() }
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: [.strictStartDate, .strictEndDate])
        let samples: [HKCategorySample] = await categorySamples(of: type, predicate: predicate)

        var summary = SleepSummary(startDate: interval.start, endDate: interval.end)
        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            guard duration > 0, duration < 12 * 3600 else { continue }
            switch HKCategoryValueSleepAnalysis(rawValue: sample.value) {
            case .asleepDeep: summary.deep += duration
            case .asleepREM: summary.rem += duration
            case .asleepCore, .asleepUnspecified: summary.core += duration
            case .awake: summary.awake += duration
            default: break
            }
            summary.total += duration
        }
        return summary
    }

    private func categorySamples(of type: HKObjectType, predicate: NSPredicate, limit: Int = HKObjectQueryNoLimit) async -> [HKCategorySample] {
        guard let sampleType = type as? HKSampleType else { return [] }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: limit, sortDescriptors: nil) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
    }

    private static var lastNightInterval: DateInterval {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        return DateInterval(
            start: todayStart.addingTimeInterval(-6 * 3600),
            end: todayStart.addingTimeInterval(12 * 3600)
        )
    }

    public static var bpm: HKUnit { .count().unitDivided(by: .minute()) }
    public static var hrvUnit: HKUnit { HKUnit.secondUnit(with: .milli) }
    public static var vo2Unit: HKUnit {
        HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))
    }
}

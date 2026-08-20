import Foundation
import Combine

@MainActor
public final class HealthModel: ObservableObject {
    @Published public private(set) var snapshot = HealthSnapshot()
    @Published public private(set) var days: [DaySnapshot] = []
    @Published public private(set) var readiness: Double?
    @Published public private(set) var bioAge: Double?
    @Published public private(set) var momentum: Scores.Momentum?
    @Published public private(set) var insights: [Insight] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var isAuthorized = false
    @Published public private(set) var authorization: HealthAuthorization = .notDetermined

    public let service = HealthService.shared
    public var chronologicalAge: Double = 30

    public init() {
        authorization = service.authorization
    }

    public func authorizeAndLoad() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.requestAuthorization()
            isAuthorized = true
            authorization = service.authorization
            await load()
        } catch {
            authorization = service.authorization
            errorMessage = error.localizedDescription
        }
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        authorization = service.authorization
        snapshot = await service.loadSnapshot()
        days = await service.dailySnapshots(days: 14)

        let baseline = Scores.baseline(from: days)
        for index in days.indices {
            days[index].readiness = Scores.readiness(day: days[index], baseline: baseline)
        }

        readiness = Scores.readiness(snapshot: snapshot)
        bioAge = Scores.biologicalAge(chronologicalAge: chronologicalAge, snapshot: snapshot)
        momentum = Scores.momentum(from: days.compactMap(\.readiness))
        insights = Insights.forToday(snapshot: snapshot)
    }

    public func clearError() {
        errorMessage = nil
    }
}

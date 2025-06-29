@testable import PrimerSDK
final class MockAnalyticsService: AnalyticsServiceProtocol {

    var events: [Analytics.Event] = []

    var onRecord: (([Analytics.Event]) -> Void)?

    func record(events: [Analytics.Event]) -> Promise<Void> {
        self.events.append(contentsOf: events)
        onRecord?(events)
        return Promise.fulfilled(())
    }

    func record(events: [Analytics.Event]) async throws {
        self.events.append(contentsOf: events)
        onRecord?(events)
    }
}

//
//  AnalyticsStorage.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 01/12/2023.
//

import Foundation

private let analyticsFileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("analytics")

protocol AnalyticsStorage {

    func loadEvents() -> [Analytics.Event]

    func save(_ events: [Analytics.Event]) throws

    func delete(_ events: [Analytics.Event])

    func delete(eventsWithUrl url: URL)

    func deleteAnalyticsFile()
}

extension Analytics {

    typealias Storage = AnalyticsStorage

    static let storage: Storage = DefaultStorage()

    class DefaultStorage: AnalyticsStorage, LogReporter {

        let fileURL: URL

        init(fileURL: URL = analyticsFileURL) {
            self.fileURL = fileURL
        }

        func loadEvents() -> [Analytics.Event] {
            do {
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    return []
                }

                let eventsData = try Data(contentsOf: fileURL)
                let events = try JSONDecoder().decode([Analytics.Event].self, from: eventsData)
                let sortedEvents = events.sorted(by: { $0.createdAt > $1.createdAt })
                return sortedEvents

            } catch {
                logger.error(message: "📚 Analytics: Failed to load analytics file. Deleting file")
                deleteAnalyticsFile()
                return []
            }
        }

        func save(_ events: [Analytics.Event]) throws {
            do {
                let eventsData = try JSONEncoder().encode(events)
                try eventsData.write(to: fileURL)
            } catch {
                logger.error(message: "📚 Analytics: Failed to save file \(error.localizedDescription)")
                throw error
            }
        }

        func delete(_ events: [Analytics.Event]) {
            guard events.count > 0 else {
                logger.warn(message: "📚 Analytics: tried to delete events but array was empty ...")
                return
            }

            logger.debug(message: "📚 Analytics: Deleting \(events.count) events")

            do {
                let storedEvents = loadEvents()
                let eventsLocalIds = events.compactMap({ $0.localId })
                let remainingEvents = storedEvents.filter({ !eventsLocalIds.contains($0.localId )})

                logger.debug(message: "📚 Analytics: Deleted \(eventsLocalIds.count) events, saving remaining \(remainingEvents.count)")

                try save(remainingEvents)
            } catch {
                logger.error(message: "📚 Analytics: Failed to save partial events before deleting file. Deleting file anyway.")
                deleteAnalyticsFile()
            }
        }

        func delete(eventsWithUrl url: URL) {
            let events = loadEvents().filter { $0.analyticsUrl == url.absoluteString }
            delete(events)
        }

        func deleteAnalyticsFile() {
            logger.debug(message: "📚 Analytics: Deleting analytics file at \(fileURL.absoluteString)")

            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try FileManager.default.removeItem(at: fileURL)

                } catch {
                    let err = PrimerError.underlyingErrors(
                        errors: [error],
                        userInfo: nil,
                        diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                }
            }
        }
    }
}

//
//  AnalyticsStorage.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 01/12/2023.
//

import Foundation

protocol AnalyticsStorage {
    
    func loadEvents() -> [Analytics.Event]
    
    func save(_ events: [Analytics.Event]) throws
    
    func delete(_ events: [Analytics.Event]?)
    
    func deleteAnalyticsFile()
}

extension Analytics {
    
    typealias Storage = AnalyticsStorage
    
    static let storage: Storage = DefaultStorage()
    
    class DefaultStorage: AnalyticsStorage, LogReporter {
        
        func loadEvents() -> [Analytics.Event] {
            do {
                guard FileManager.default.fileExists(atPath: Analytics.Service.filepath.path) else {
                    return []
                }

                let eventsData = try Data(contentsOf: Analytics.Service.filepath)
                let events = try JSONDecoder().decode([Analytics.Event].self, from: eventsData)
                let sortedEvents = events.sorted(by: { $0.createdAt > $1.createdAt })
                return sortedEvents

            } catch {
                deleteAnalyticsFile()
                return []
            }
        }

        func save(_ events: [Analytics.Event]) throws {
            do {
                let eventsData = try JSONEncoder().encode(events)
                try eventsData.write(to: Analytics.Service.filepath)
                //                    logger.debug(message: "📚 Analytics: Saved \(events.count) events")
            } catch {
                logger.error(message: "📚 Analytics: Failed to save file \(error.localizedDescription)")
                throw error
            }
        }

        func delete(_ events: [Analytics.Event]?) {
            logger.debug(message: "📚 Analytics: Deleting \(events == nil ? "all" : "\(events!.count)") events")

            do {
                if let events = events {
                    let storedEvents = loadEvents()
                    let eventsLocalIds = events.compactMap({ $0.localId })
                    let remainingEvents = storedEvents.filter({ !eventsLocalIds.contains($0.localId )})
                    
                    logger.debug(message: "📚 Analytics: Deleted \(eventsLocalIds.count) events, saving remaining \(remainingEvents.count)")
                    
                    try save(remainingEvents)
                } else {
                    deleteAnalyticsFile()
                }
            } catch {
                logger.error(message: "📚 Analytics: Failed to save partial events before deleting file. Deleting file anyway.")
                deleteAnalyticsFile()
            }
        }

        func deleteAnalyticsFile() {
            logger.debug(message: "📚 Analytics: Deleting analytics file at \(Analytics.Service.filepath.absoluteString)")

            if #available(iOS 16.0, *) {
                if FileManager.default.fileExists(atPath: Analytics.Service.filepath.path()) {
                    do {
                        try FileManager.default.removeItem(at: Analytics.Service.filepath)

                    } catch {
                        let err = PrimerError.underlyingErrors(
                            errors: [error],
                            userInfo: nil,
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                    }
                }
            } else {
                if FileManager.default.fileExists(atPath: Analytics.Service.filepath.path) {
                    do {
                        try FileManager.default.removeItem(at: Analytics.Service.filepath)

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
}

//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

import Foundation

extension Analytics {

    internal class Service: LogReporter {

        static let sdkLogsUrl = URL(string: "https://analytics.production.data.primer.io/sdk-logs")!
        
        static let maximumBatchSize: UInt = 100
        
        static private var isSyncing: Bool = false

        @discardableResult
        internal static func record(event: Analytics.Event) -> Promise<Void> {
            Analytics.Service.record(events: [event])
        }

        @discardableResult
        internal static func record(events: [Analytics.Event]) -> Promise<Void> {
            return Promise { seal in
                Analytics.queue.async(flags: .barrier) {
                    logger.debug(message: "📚 Analytics: Recording \(events.count) events")
                    let storedEvents: [Analytics.Event] = storage.loadEvents()

                    let storedEventsIds = storedEvents.compactMap({ $0.localId })
                    var eventsToAppend: [Analytics.Event] = []

                    for event in events {
                        if storedEventsIds.contains(event.localId) { continue }
                        eventsToAppend.append(event)
                    }

                    var combinedEvents: [Analytics.Event] = eventsToAppend.sorted(by: { $0.createdAt > $1.createdAt })
                    combinedEvents.append(contentsOf: storedEvents)
                    
                    do {
                        try storage.save(combinedEvents)
                        
                        if combinedEvents.count > 100 {
                            sync(events: combinedEvents)
                        }

                        seal.fulfill()
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
        
        @discardableResult
        internal static func flush() -> Promise<Void> {
            Promise { seal in
                let events = storage.loadEvents()
                sync(events: events, isFlush: true)
                .done {
                    seal.fulfill()
                }.catch { error in
                    seal.reject(error)
                }
            }
        }

        @discardableResult
        private static func sync(events: [Analytics.Event]? = nil, isFlush: Bool = false) -> Promise<Void> {
            if !isFlush {
                guard !isSyncing else { return Promise<Void> { $0.fulfill() } }
                isSyncing = true
            }
            return Promise<Void> { seal in
                Analytics.queue.async(flags: .barrier) {
                    logger.debug(message: "📚 Analytics : Syncing...")
                    
                    var events = events ?? []
                    guard events.count > 0 else {
                        logger.warn(message: "📚 Analytics [sync]: Attempted to sync but had no events")
                        return
                    }
                    
                    events = isFlush ? events : Array(events.prefix(Int(maximumBatchSize)))
                    
                    let promises: [Promise<Void>] = [
                        Analytics.Service.sendSkdLogEvents(events: events),
                        Analytics.Service.sendSkdAnalyticsEvents(events: events)
                    ]
                    
                    when(fulfilled: promises)
                        .done { _ in
                            logger.debug(message: "📚 Analytics: All events synced...")
                        }
                        .ensure {
                        }
                        .catch { err in
                            logger.error(message: "📚 Analytics: Failed to sync events with error \(err.localizedDescription)")
                        }
                        .finally {
                            let remainingEvents = storage.loadEvents()
                            logger.debug(message: "📚 Analytics: Sync completed. \(remainingEvents.count) events present after sync.")
                            isSyncing = false
                            seal.fulfill()
                        }
                }
            }
        }
        
        static func clear() {
            storage.deleteAnalyticsFile()
        }

        private static func sendSkdLogEvents(events: [Analytics.Event]) -> Promise<Void> {
            let storedEvents = events
            let sdkLogEvents = storedEvents.filter({ $0.analyticsUrl == nil })
            let sdkLogEventsBatches = sdkLogEvents.toBatches(of: maximumBatchSize)

            var promises: [Promise<Void>] = []

            for sdkLogEventsBatch in sdkLogEventsBatches {
                let p = Analytics.Service.sendEvents(sdkLogEventsBatch, to: Analytics.Service.sdkLogsUrl)
                promises.append(p)
            }

            return when(fulfilled: promises)
        }

        private static func sendSkdAnalyticsEvents(events: [Analytics.Event]) -> Promise<Void> {
            let storedEvents = events
            let analyticsEvents = storedEvents.filter({ $0.analyticsUrl != nil })
            let analyticsEventsBatches = analyticsEvents.toBatches(of: maximumBatchSize)

            var promises: [Promise<Void>] = []

            if let analyticsUrlStr = analyticsEvents.first(where: { $0.analyticsUrl != nil })?.analyticsUrl,
               let analyticsUrl = URL(string: analyticsUrlStr) {
                for analyticsEventsBatch in analyticsEventsBatches {
                    let p = sendEvents(analyticsEventsBatch, to: analyticsUrl)
                    promises.append(p)
                }
            }
            
            return when(fulfilled: promises)
        }

        private static func sendEvents(
            _ events: [Analytics.Event],
            to url: URL
        ) -> Promise<Void> {
            return Promise { seal in
                Analytics.Service.sendEvents(events, to: url) { err in
                    if let err = err {
                        seal.reject(err)
                    } else {
                        seal.fulfill()
                    }
                }
            }
        }

        private static func sendEvents(
            _ events: [Analytics.Event],
            to url: URL,
            completion: @escaping (Error?) -> Void
        ) {
            if events.isEmpty {
                completion(nil)
                return
            }

            if url.absoluteString != Analytics.Service.sdkLogsUrl.absoluteString, PrimerAPIConfigurationModule.clientToken?.decodedJWTToken == nil {
                // Sync another time
                completion(nil)
                return
            }

            let decodedJWTToken = PrimerAPIConfigurationModule.clientToken?.decodedJWTToken

            let apiClient: PrimerAPIClientProtocol = Analytics.apiClient ?? PrimerAPIClient()
            
            logger.debug(message: "📚 Analytics: Sending \(events.count) events to \(url.absoluteString)")
            
            apiClient.sendAnalyticsEvents(
                clientToken: decodedJWTToken,
                url: url,
                body: events
            ) { result in
                switch result {
                case .success:
                    logger.debug(message: "📚 Analytics: Finished syncing \(events.count) events on URL: \(url.absoluteString)")
                    storage.delete(events)
                    completion(nil)

                case .failure(let err):
                    logger.error(message: "📚 Analytics: Failed to sync \(events.count) events on URL \(url.absoluteString) with error \(err)")
                    ErrorHandler.handle(error: err)
                    completion(err)
                }
            }
        }

        struct Response: Decodable {
            let id: String?
            let result: String?
        }
    }
}

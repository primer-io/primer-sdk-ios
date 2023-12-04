//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

import Foundation

extension Analytics {

    internal class Service: LogReporter {

        static let defaultSdkLogsUrl = URL(string: "https://analytics.production.data.primer.io/sdk-logs")!
        
        static let maximumBatchSize: UInt = 100
        
        static let shared = Service(sdkLogsUrl: Service.defaultSdkLogsUrl,
                                    batchSize: Service.maximumBatchSize,
                                    storage: Analytics.storage)
        
        let sdkLogsUrl: URL
        
        let batchSize: UInt
        
        let storage: Storage
        
        private var isSyncing: Bool = false
        
        init(sdkLogsUrl: URL, batchSize: UInt, storage: Storage) {
            self.sdkLogsUrl = sdkLogsUrl
            self.batchSize = batchSize
            self.storage = storage
        }

        @discardableResult
        internal func record(event: Analytics.Event) -> Promise<Void> {
            self.record(events: [event])
        }

        @discardableResult
        internal func record(events: [Analytics.Event]) -> Promise<Void> {
            return Promise { seal in
                Analytics.queue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }

                    self.logger.debug(message: "📚 Analytics: Recording \(events.count) events")
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
                            self.sync(events: combinedEvents)
                        }

                        seal.fulfill()
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
        
        @discardableResult
        internal func flush() -> Promise<Void> {
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
        private func sync(events: [Analytics.Event]? = nil, isFlush: Bool = false) -> Promise<Void> {
            if !isFlush {
                guard !isSyncing else { return Promise<Void> { $0.fulfill() } }
                isSyncing = true
            }
            return Promise<Void> { seal in
                Analytics.queue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }
                    self.logger.debug(message: "📚 Analytics : Syncing...")
                    
                    var events = events ?? []
                    guard events.count > 0 else {
                        self.logger.warn(message: "📚 Analytics [sync]: Attempted to sync but had no events")
                        return
                    }
                    
                    events = isFlush ? events : Array(events.prefix(Int(batchSize)))
                    
                    let promises: [Promise<Void>] = [
                        self.sendSkdLogEvents(events: events),
                        self.sendSkdAnalyticsEvents(events: events)
                    ]
                    
                    when(fulfilled: promises)
                        .done { _ in
                            self.logger.debug(message: "📚 Analytics: All events synced...")
                        }
                        .ensure {
                        }
                        .catch { err in
                            self.logger.error(message: "📚 Analytics: Failed to sync events with error \(err.localizedDescription)")
                        }
                        .finally {
                            let remainingEvents = self.storage.loadEvents()
                            self.logger.debug(message: "📚 Analytics: Sync completed. \(remainingEvents.count) events present after sync.")
                            self.isSyncing = false
                            seal.fulfill()
                        }
                }
            }
        }
        
        func clear() {
            storage.deleteAnalyticsFile()
        }

        private func sendSkdLogEvents(events: [Analytics.Event]) -> Promise<Void> {
            let storedEvents = events
            let sdkLogEvents = storedEvents.filter({ $0.analyticsUrl == nil })
            let sdkLogEventsBatches = sdkLogEvents.toBatches(of: batchSize)

            var promises: [Promise<Void>] = []

            for sdkLogEventsBatch in sdkLogEventsBatches {
                let p = self.sendEvents(sdkLogEventsBatch, to: self.sdkLogsUrl)
                promises.append(p)
            }

            return when(fulfilled: promises)
        }

        private func sendSkdAnalyticsEvents(events: [Analytics.Event]) -> Promise<Void> {
            let storedEvents = events
            let analyticsEvents = storedEvents.filter({ $0.analyticsUrl != nil })
            let analyticsEventsBatches = analyticsEvents.toBatches(of: batchSize)

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

        private func sendEvents(
            _ events: [Analytics.Event],
            to url: URL
        ) -> Promise<Void> {
            return Promise { seal in
                self.sendEvents(events, to: url) { err in
                    if let err = err {
                        seal.reject(err)
                    } else {
                        seal.fulfill()
                    }
                }
            }
        }

        private func sendEvents(
            _ events: [Analytics.Event],
            to url: URL,
            completion: @escaping (Error?) -> Void
        ) {
            if events.isEmpty {
                completion(nil)
                return
            }

            if url.absoluteString != self.sdkLogsUrl.absoluteString, PrimerAPIConfigurationModule.clientToken?.decodedJWTToken == nil {
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
                    self.logger.debug(message: "📚 Analytics: Finished syncing \(events.count) events on URL: \(url.absoluteString)")
                    self.storage.delete(events)
                    completion(nil)

                case .failure(let err):
                    self.logger.error(message: "📚 Analytics: Failed to sync \(events.count) events on URL \(url.absoluteString) with error \(err)")
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

extension Analytics.Service {
    static func record(event: Analytics.Event) -> Promise<Void> {
        shared.record(event: event)
    }

    static func record(events: [Analytics.Event]) -> Promise<Void> {
        shared.record(events: events)
    }
    
    static func flush() -> Promise<Void> {
        shared.flush()
    }
    
    static func clear() {
        shared.clear()
    }
}


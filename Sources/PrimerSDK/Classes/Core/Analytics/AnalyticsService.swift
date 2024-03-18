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

        static var shared = {
            Service(sdkLogsUrl: Service.defaultSdkLogsUrl,
                    batchSize: Service.maximumBatchSize,
                    storage: Analytics.storage,
                    apiClient: Analytics.apiClient ?? PrimerAPIClient())
        }()

        let sdkLogsUrl: URL

        let batchSize: UInt

        let storage: Storage

        let apiClient: PrimerAPIClientAnalyticsProtocol

        var eventSendFailureCount: UInt = 0

        private var isSyncing: Bool = false

        init(sdkLogsUrl: URL,
             batchSize: UInt,
             storage: Storage,
             apiClient: PrimerAPIClientAnalyticsProtocol) {
            self.sdkLogsUrl = sdkLogsUrl
            self.batchSize = batchSize
            self.storage = storage
            self.apiClient = apiClient
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

                    let storedEvents: [Analytics.Event] = self.storage.loadEvents()

                    let storedEventsIds = storedEvents.compactMap({ $0.localId })
                    var eventsToAppend: [Analytics.Event] = []

                    for event in events {
                        if storedEventsIds.contains(event.localId) { continue }
                        eventsToAppend.append(event)
                    }

                    var combinedEvents: [Analytics.Event] = eventsToAppend.sorted(by: { $0.createdAt > $1.createdAt })
                    combinedEvents.append(contentsOf: storedEvents)

                    self.logger.debug(message: "📚 Analytics: Recording \(events.count) events (new total: \(combinedEvents.count))")

                    do {
                        try self.storage.save(combinedEvents)

                        if combinedEvents.count >= self.batchSize {
                            let batchSizeExceeded = combinedEvents.count > self.batchSize
                            let sizeString = batchSizeExceeded ? "exceeded" : "reached"
                            let count = combinedEvents.count
                            let message = "📚 Analytics: Minimum batch size of \(self.batchSize) \(sizeString) (\(count) events present). Attempting sync ..."
                            self.logger.debug(message: message)
                            _ = self.sync(events: combinedEvents).ensure {
                                seal.fulfill()
                            }
                        } else {
                            seal.fulfill()
                        }

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
        private func sync(events: [Analytics.Event], isFlush: Bool = false) -> Promise<Void> {
            let syncType = isFlush ? "flush" : "sync"
            guard events.count > 0 else {
                self.logger.warn(message: "📚 Analytics: Attempted to \(syncType) but had no events")
                return Promise<Void> { $0.fulfill() }
            }

            if !isFlush {
                guard !isSyncing else {
                    self.logger.debug(message: "📚 Analytics: Attempted to sync while already syncing. Skipping ...")
                    return Promise<Void> { $0.fulfill() }
                }
                isSyncing = true
            }

            return Promise<Void> { seal in
                Analytics.queue.async(flags: .barrier) { [weak self] in
                    guard let self = self else { return }

                    let events = isFlush ? events : Array(events.prefix(Int(self.batchSize)))

                    self.logger.debug(message: "📚 Analytics: \(syncType.capitalized)ing \(events.count) events ...")

                    let promises: [Promise<Void>] = [
                        self.sendSdkLogEvents(events: events),
                        self.sendSdkAnalyticsEvents(events: events)
                    ]

                    when(fulfilled: promises)
                        .done { _ in
                            let remainingEvents = self.storage.loadEvents()
                            self.logger.debug(message: "📚 Analytics: \(syncType.capitalized) completed. \(remainingEvents.count) events remain")
                            self.isSyncing = false
                            seal.fulfill()
                            if remainingEvents.count >= self.batchSize {
                                self.sync(events: remainingEvents)
                            }
                        }
                        .catch { err in
                            let errorMessage = err.localizedDescription
                            let message = "📚 Analytics: Failed to \(syncType) events with error \(errorMessage)"
                            self.logger.error(message: message)
                            self.isSyncing = false
                            seal.reject(err)
                        }
                }
            }
        }

        func clear() {
            storage.deleteAnalyticsFile()
        }

        private func sendSdkLogEvents(events: [Analytics.Event]) -> Promise<Void> {
            let storedEvents = events
            let sdkLogEvents = storedEvents.filter({ $0.analyticsUrl == nil })
            let sdkLogEventsBatches = sdkLogEvents.toBatches(of: batchSize)

            var promises: [Promise<Void>] = []

            for sdkLogEventsBatch in sdkLogEventsBatches {
                let promise = self.sendEvents(sdkLogEventsBatch, to: self.sdkLogsUrl)
                promises.append(promise)
            }

            return when(fulfilled: promises)
        }

        private func sendSdkAnalyticsEvents(events: [Analytics.Event]) -> Promise<Void> {
            let events = events.filter({ $0.analyticsUrl != nil })

            let urls = Set(events.compactMap { $0.analyticsUrl }).compactMap { URL(string: $0) }
            let eventSets = urls.map { url in
                (url: url, events: events.filter { $0.analyticsUrl == url.absoluteString })
            }

            let promises = eventSets.map { item in
                sendSdkAnalyticsEvents(url: item.url, events: item.events)
            }

            return when(fulfilled: promises)
        }

        private func sendSdkAnalyticsEvents(url: URL, events: [Analytics.Event]) -> Promise<Void> {
            let batches = events.toBatches(of: batchSize)

            var promises: [Promise<Void>] = []

            for batch in batches {
                let promise = sendEvents(batch, to: url)
                promises.append(promise)
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

            if url.absoluteString != self.sdkLogsUrl.absoluteString,
               PrimerAPIConfigurationModule.clientToken?.decodedJWTToken == nil {
                // Sync another time
                completion(nil)
                return
            }

            let decodedJWTToken = PrimerAPIConfigurationModule.clientToken?.decodedJWTToken

            logger.debug(message: "📚 Analytics: Sending \(events.count) events to \(url.absoluteString)")

            self.apiClient.sendAnalyticsEvents(
                clientToken: decodedJWTToken,
                url: url,
                body: events
            ) { result in
                switch result {
                case .success:
                    Analytics.queue.async {
                        let urlString = url.absoluteString
                        self.storage.delete(events)
                        let message = "📚 Analytics: Finished sending \(events.count) events on URL: \(urlString). Deleted \(events.count) sent events from store"
                        self.logger.debug(message: message)
                        completion(nil)
                    }
                case .failure(let err):
                    Analytics.queue.async {
                        // Log failure
                        let urlString = url.absoluteString
                        let count = events.count
                        let message = "📚 Analytics: Failed to send \(count) events on URL \(urlString) with error \(err)"
                        self.logger.error(message: message)

                        // Handle error
                        ErrorHandler.handle(error: err)
                        self.handleFailedEvents(forUrl: url)
                        completion(err)
                    }
                }
            }
        }

        private func handleFailedEvents(forUrl url: URL) {
            self.eventSendFailureCount += 1
            if eventSendFailureCount >= 3 {
                logger.error(message: "Failed to send events three or more times. Deleting analytics file ...")
                storage.deleteAnalyticsFile()
                eventSendFailureCount = 0
            } else {
                self.storage.delete(eventsWithUrl: url)
            }
        }

        // swiftlint:disable:next nesting
        struct Response: Decodable {
            let id: String?
            let result: String?
        }
    }
}

extension Analytics.Service {
    @discardableResult static func record(event: Analytics.Event) -> Promise<Void> {
        shared.record(event: event)
    }

    @discardableResult static func record(events: [Analytics.Event]) -> Promise<Void> {
        shared.record(events: events)
    }

    @discardableResult static func flush() -> Promise<Void> {
        shared.flush()
    }

    static func clear() {
        shared.clear()
    }
}

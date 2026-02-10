//
//  AnalyticsService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length

import Foundation
import PrimerStepResolver

protocol AnalyticsServiceProtocol: Actor {
    func record(events: [Analytics.Event]) async throws
    func fire(events: [Analytics.Event])
    func record(event: Analytics.Event) async throws
    func fire(event: Analytics.Event)
}

extension Analytics {

    final actor Service: AnalyticsServiceProtocol, LogReporter {

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
            Task { await PrimerStepResolverRegistry.shared.register(self, forStepType: .analyticsLog) }
        }

        func record(events: [Analytics.Event]) async throws {
            let storedEvents: [Analytics.Event] = storage.loadEvents()
            let storedEventsIds = storedEvents.map(\.localId)
            var eventsToAppend: [Analytics.Event] = []

            for event in events {
                if storedEventsIds.contains(event.localId) { continue }
                eventsToAppend.append(event)
            }

            var combinedEvents: [Analytics.Event] = eventsToAppend.sorted(by: { $0.createdAt > $1.createdAt })
            combinedEvents.append(contentsOf: storedEvents)

            logger.debug(message: "📚 Analytics: Recording \(events.count) events (new total: \(combinedEvents.count))")

            do {
                try storage.save(combinedEvents)

                if combinedEvents.count >= batchSize {
                    let hasEventsRequiringToken = combinedEvents.contains { $0.analyticsUrl != nil }
                    let hasClientToken = PrimerAPIConfigurationModule.clientToken?.decodedJWTToken != nil

                    if hasEventsRequiringToken, !hasClientToken {
                        return
                    } else {
                        let batchSizeExceeded = combinedEvents.count > batchSize
                        let sizeString = batchSizeExceeded ? "exceeded" : "reached"
                        let count = combinedEvents.count
                        let message =
                            "📚 Analytics: Minimum batch size of \(batchSize) \(sizeString) (\(count) events present). Attempting sync ..."
                        logger.debug(message: message)
                        Task {
                            do {
                                try await sync(events: combinedEvents)
                            } catch {
                                // Ignore errors during sync
                            }
                        }
                    }
                } else {
                    return
                }
            } catch {
                throw error
            }
        }

        func fire(events: [Analytics.Event]) {
            Task {
                try? await self.record(events: events)
            }
        }

        func record(event: Analytics.Event) async throws {
            try await record(events: [event])
        }

        func fire(event: Analytics.Event) {
            Task {
                try? await self.record(events: [event])
            }
        }

        func flush() async throws {
            try await sync(events: storage.loadEvents(), isFlush: true)
        }

        func drain() {
            Task {
                try? await self.flush()
            }
        }

        private func sync(events: [Analytics.Event], isFlush: Bool = false) async throws {
            let syncType = isFlush ? "flush" : "sync"
            guard !events.isEmpty else { return logger.warn(message: "📚 Analytics: Attempted to \(syncType) but had no events")}

            if !isFlush {
                guard !isSyncing else { return logger.debug(message: "📚 Analytics: Attempted to sync while already syncing. Skipping ...") }
                isSyncing = true
            }

            defer { isSyncing = isFlush ? isSyncing : false }

            let eventsToSend = isFlush ? events : Array(events.prefix(Int(batchSize)))
            logger.debug(message: "📚 Analytics: \(syncType.capitalized)ing \(eventsToSend.count) events ...")
            async let logEvents: Void = sendSdkLogEvents(events: eventsToSend)
            async let analyticsEvents: Void = sendSdkAnalyticsEvents(events: eventsToSend)
            _ = try await (logEvents, analyticsEvents)

            let remainingEvents = storage.loadEvents()
            logger.debug(message: "📚 Analytics: \(syncType.capitalized) completed. \(remainingEvents.count) events remain")
            if remainingEvents.count >= batchSize { try? await sync(events: remainingEvents) }
        }

        func clear() {
            storage.deleteAnalyticsFile()
        }

        private func sendSdkLogEvents(events: [Analytics.Event]) async throws {
            let sdkLogEvents = events.filter { $0.analyticsUrl == nil }
            let sdkLogEventsBatches = sdkLogEvents.toBatches(of: batchSize)

            for batch in sdkLogEventsBatches {
                try await sendEvents(batch, to: sdkLogsUrl)
            }
        }

        private func sendSdkAnalyticsEvents(events: [Analytics.Event]) async throws {
            let events = events.filter { $0.analyticsUrl != nil }
            let urls = Set(events.compactMap(\.analyticsUrl).compactMap(URL.init))
            let eventSets = urls.map { url in
                (url: url, events: events.filter { $0.analyticsUrl == url.absoluteString })
            }

            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in eventSets {
                    group.addTask {
                        try await self.sendSdkAnalyticsEvents(url: item.url, events: item.events)
                    }
                }
                try await group.waitForAll()
            }
        }

        private func sendSdkAnalyticsEvents(url: URL, events: [Analytics.Event]) async throws {
            let batches = events.toBatches(of: batchSize)
            for batch in batches {
                try await sendEvents(batch, to: url)
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
                // Skip sending events that require client token when no token is available
                // (This is already handled at record() level, but we double-check here as a safety measure)
                logger.debug(message: "📚 Analytics: Skipping \(events.count) events - no client token available for URL: \(url.absoluteString)")
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
                Task { [weak self] in
                    guard let self else { return }
                    let messageContent = "\(events.count) events on URL \(url.absoluteString)"
                    switch result {
                    case .success:
                        self.storage.delete(events)
                        self.logger.debug(message: "📚 Analytics: Finished sending \(messageContent)")
                        completion(nil)
                    case let .failure(err):
                        self.logger.error(message: "📚 Analytics: Failed to send \(messageContent) with error \(err)")
                        await self.handleFailedEvents(forUrl: url)
                        completion(handled(error: err))
                    }
                }
            }
        }

        private func sendEvents(_ events: [Analytics.Event], to url: URL) async throws {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                sendEvents(events, to: url) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
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
    static func record(event: Analytics.Event) async throws {
        try await shared.record(event: event)
    }

    static func fire(event: Analytics.Event) {
        Task { await shared.fire(event: event) }
    }

    static func record(events: [Analytics.Event]) async throws {
        try await shared.record(events: events)
    }

    static func fire(events: [Analytics.Event]) {
        Task { await shared.fire(events: events) }
    }

    static func flush() async throws {
        try await shared.flush()
    }

    static func drain() {
        Task { await shared.drain() }
    }

    static func clear() {
        Task { await shared.clear() }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable file_length

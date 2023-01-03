//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation

extension Analytics {
    
    internal class Service {
        
        static var filepath: URL = {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("analytics")
            primerLogAnalytics(
                title: "Analytics URL",
                message: "Analytics URL:\n\(url)\n",
                file: #file,
                className: "Analytics.Service",
                function: #function,
                line: #line)
            return url
        }()
        
        static var lastSyncAt: Date? {
            get {
                guard let lastSyncAtStr = UserDefaults.primerFramework.string(forKey: "primer.analytics.lastSyncAt") else { return nil }
                guard let lastSyncAt = lastSyncAtStr.toDate() else { return nil }
                return lastSyncAt
            }
            set {
                let lastSyncAtStr = newValue?.toString()
                UserDefaults.primerFramework.set(lastSyncAtStr, forKey: "primer.analytics.lastSyncAt")
                UserDefaults.primerFramework.synchronize()
            }
        }
        
        internal static func loadEvents() -> [Event] {
            primerLogAnalytics(
                title: "ANALYTICS",
                message: "📚 Loading events",
                prefix: "📚",
                bundle: Bundle.primerFrameworkIdentifier,
                file: #file, className: "\(Self.self)",
                function: #function,
                line: #line)
            
            guard let eventsData = try? Data(contentsOf: Analytics.Service.filepath) else { return [] }
            let events = (try? JSONDecoder().decode([Analytics.Event].self, from: eventsData)) ?? []
            return events.sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        internal static func record(event: Analytics.Event) {
            Analytics.Service.record(events: [event])
        }
        
        internal static func record(events: [Analytics.Event]) {
            primerLogAnalytics(
                title: "ANALYTICS",
                message: "📚 Recording \(events.count) events",
                prefix: "📚",
                bundle: Bundle.primerFrameworkIdentifier,
                file: #file, className: "\(Self.self)",
                function: #function,
                line: #line)
            
            Analytics.queue.async {
                var tmpEvents = Analytics.Service.loadEvents()
                tmpEvents.append(contentsOf: events)
                let sortedEvents = tmpEvents.sorted(by: { $0.createdAt < $1.createdAt })
                try? Analytics.Service.save(events: sortedEvents)
            }
        }
        
        private static func save(events: [Analytics.Event]) throws {
            primerLogAnalytics(
                title: "ANALYTICS",
                message: "📚 Saving \(events.count) events",
                prefix: "📚",
                bundle: Bundle.primerFrameworkIdentifier,
                file: #file, className: "\(Self.self)",
                function: #function,
                line: #line)
            
            Analytics.Event.omitLocalParametersEncoding = false
            let eventsData = try JSONEncoder().encode(events)
            try eventsData.write(to: Analytics.Service.filepath)
        }
        
        internal static func deleteEvents(_ events: [Analytics.Event]? = nil) throws {
            primerLogAnalytics(
                title: "ANALYTICS",
                message: "📚 Deleting \(events == nil ? "all" : "\(events!.count)") events",
                prefix: "📚",
                bundle: Bundle.primerFrameworkIdentifier,
                file: #file, className: "\(Self.self)",
                function: #function,
                line: #line)
            
            if let events = events {
                let eventsIds = events.compactMap({ $0.localId })
                let allEvents = Analytics.Service.loadEvents()
                let remainingEvents = allEvents.filter({ !eventsIds.contains($0.localId ?? "") })
                try save(events: remainingEvents)
            } else {
                try Analytics.Service.save(events: [])
            }
        }
        
        internal static func sync(batchSize: UInt = 100) {
            let analyticsUrlStr = PrimerAPIConfigurationModule.decodedJWTToken?.analyticsUrlV2 ?? "https://analytics.production.data.primer.io/sdk-logs"
            guard let analyticsUrl = URL(string: analyticsUrlStr) else { return }
            
            primerLogAnalytics(
                title: "ANALYTICS",
                message: "📚 Analytics URL: \(analyticsUrlStr)",
                prefix: "📚",
                bundle: Bundle.primerFrameworkIdentifier,
                file: #file, className: "\(Self.self)",
                function: #function,
                line: #line)
            
            Analytics.queue.async {
                primerLogAnalytics(
                    title: "ANALYTICS",
                    message: "📚 Syncing...",
                    prefix: "📚",
                    bundle: Bundle.primerFrameworkIdentifier,
                    file: #file, className: "\(Self.self)",
                    function: #function,
                    line: #line)
                
                var storedEvents = Analytics.Service.loadEvents()
                if storedEvents.count > batchSize {
                    storedEvents = Array(storedEvents[0..<Int(batchSize)])
                }
                
                Analytics.Event.omitLocalParametersEncoding = true
                let requestBody = Analytics.Service.Request(data: storedEvents)
                
                primerLogAnalytics(
                    title: "ANALYTICS",
                    message: "📚 Syncing \(storedEvents.count) events on URL: \(analyticsUrlStr)",
                    prefix: "📚",
                    bundle: Bundle.primerFrameworkIdentifier,
                    file: #file, className: "\(Self.self)",
                    function: #function,
                    line: #line)
                
                let apiClient: PrimerAPIClientProtocol = Analytics.apiClient ?? PrimerAPIClient()
                apiClient.sendAnalyticsEvents(url: analyticsUrl, body: requestBody) { result in
                    Analytics.Event.omitLocalParametersEncoding = false
                    
                    switch result {
                    case .success:
                        primerLogAnalytics(
                            title: "ANALYTICS",
                            message: "📚 Finished syncing \(storedEvents.count) events on URL: \(analyticsUrlStr)",
                            prefix: "📚",
                            bundle: Bundle.primerFrameworkIdentifier,
                            file: #file, className: "\(Self.self)",
                            function: #function,
                            line: #line)
                        
                        do {
                            try Analytics.Service.deleteEvents(storedEvents)
                        } catch {
                            ErrorHandler.handle(error: error)
                            return
                        }
                        
                        self.lastSyncAt = Date()
                        
                        let remainingEvents = Analytics.Service.loadEvents()
                            .filter({ $0.eventType != Analytics.Event.EventType.networkCall && $0.eventType != Analytics.Event.EventType.networkConnectivity })
                        if !remainingEvents.isEmpty {
                            primerLogAnalytics(
                                title: "ANALYTICS",
                                message: "📚 \(remainingEvents.count) events remain for URL: \(analyticsUrlStr)",
                                prefix: "📚",
                                bundle: Bundle.primerFrameworkIdentifier,
                                file: #file, className: "\(Self.self)",
                                function: #function,
                                line: #line)
                            
                            Analytics.Service.sync()
                        }
                        
                    case .failure(let err):
                        primerLogAnalytics(
                            title: "ANALYTICS",
                            message: "📚 Failed to sync \(storedEvents.count) events on URL \(analyticsUrlStr) with error \(err)",
                            prefix: "📚",
                            bundle: Bundle.primerFrameworkIdentifier,
                            file: #file, className: "\(Self.self)",
                            function: #function,
                            line: #line)
                    }
                }
            }
        }
        
        struct Request: Encodable {
            let data: [Analytics.Event]
        }
        
        struct Response: Decodable {
            let id: String?
            let result: String?
        }
        
    }
}

#endif

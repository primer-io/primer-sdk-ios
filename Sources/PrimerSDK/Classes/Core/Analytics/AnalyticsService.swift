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
            log(logLevel: .info, title: "Analytics URL", message: "Analytics URL:\n\(url)\n", file: #file, className: "Analytics.Service", function: #function, line: #line)
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
        
        private static func loadEvents() -> [Event] {
            log(logLevel: .debug,
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
            log(logLevel: .debug,
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
            log(logLevel: .debug,
                title: "ANALYTICS",
                message: "📚 Saving \(events.count) events",
                prefix: "📚",
                bundle: Bundle.primerFrameworkIdentifier,
                file: #file, className: "\(Self.self)",
                function: #function,
                line: #line)
            
            let eventsData = try JSONEncoder().encode(events)
            try eventsData.write(to: Analytics.Service.filepath)
        }
        
        internal static func deleteEvents(_ events: [Analytics.Event]? = nil) throws {
            log(logLevel: .debug,
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
            Analytics.queue.async {
                log(logLevel: .debug,
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
                
                let analyticsUrlStrs: [String?] = Array(Set(storedEvents.map({ $0.analyticsUrl })))
                log(logLevel: .debug,
                    title: "ANALYTICS",
                    message: "📚 Analytics URLs: \(analyticsUrlStrs)",
                    prefix: "📚",
                    bundle: Bundle.primerFrameworkIdentifier,
                    file: #file, className: "\(Self.self)",
                    function: #function,
                    line: #line)
                
                for analyticsUrlStr in analyticsUrlStrs {
                    let events = storedEvents.filter({ $0.analyticsUrl == analyticsUrlStr })
                    // FIXME: Change hardcoded URL
                    let urlStr = analyticsUrlStr ?? "https://us-central1-primerdemo-8741b.cloudfunctions.net/api/analytics/\(Primer.shared.sdkSessionId)"
                    guard let url = URL(string: urlStr) else { continue }
                    
                    var _events = events
                    for (i, _) in _events.enumerated() {
                        _events[i].localId = nil
                        _events[i].analyticsUrl = nil
                    }
                    
                    let requestBody = Analytics.Service.Request(data: _events)
                    
                    log(logLevel: .debug,
                        title: "ANALYTICS",
                        message: "📚 Syncing \(events.count) events on URL: \(analyticsUrlStr ?? "nil")",
                        prefix: "📚",
                        bundle: Bundle.primerFrameworkIdentifier,
                        file: #file, className: "\(Self.self)",
                        function: #function,
                        line: #line)
                    
                    let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
                    client.sendAnalyticsEvent(url: url, body: requestBody) { result in
                        switch result {
                        case .success:
                            log(logLevel: .debug,
                                title: "ANALYTICS",
                                message: "📚 Finished syncing \(events.count) events on URL: \(analyticsUrlStr ?? "nil")",
                                prefix: "📚",
                                bundle: Bundle.primerFrameworkIdentifier,
                                file: #file, className: "\(Self.self)",
                                function: #function,
                                line: #line)
                            
                            do {
                                try Analytics.Service.deleteEvents(events)
                            } catch {
                                _ = ErrorHandler.shared.handle(error: error)
                                return
                            }
                            
                            self.lastSyncAt = Date()
                            
                            let remainingEvents = Analytics.Service.loadEvents()
                                .filter({ $0.analyticsUrl == analyticsUrlStr })
                                .filter({ $0.eventType != Analytics.Event.EventType.networkCall && $0.eventType != Analytics.Event.EventType.networkConnectivity })
                            if !remainingEvents.isEmpty {
                                log(logLevel: .debug,
                                    title: "ANALYTICS",
                                    message: "📚 \(remainingEvents.count) events remain for URL: \(analyticsUrlStr ?? "nil")",
                                    prefix: "📚",
                                    bundle: Bundle.primerFrameworkIdentifier,
                                    file: #file, className: "\(Self.self)",
                                    function: #function,
                                    line: #line)
                                
                                Analytics.Service.sync()
                            }
                            
                        case .failure(let err):
                            log(logLevel: .debug,
                                title: "ANALYTICS",
                                message: "📚 Failed to sync \(events.count) events on URL \(analyticsUrlStr ?? "nil") with error \(err)",
                                prefix: "📚",
                                bundle: Bundle.primerFrameworkIdentifier,
                                file: #file, className: "\(Self.self)",
                                function: #function,
                                line: #line)
                        }
                    }
                }
            }
        }
        
        struct Request: Encodable {
            let data: [Analytics.Event]
        }
        
        struct Response: Decodable {
            let success: Bool
        }
        
    }
    
}

#endif

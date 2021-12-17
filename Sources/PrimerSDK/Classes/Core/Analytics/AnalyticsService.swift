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
            
            guard let eventsData = try? Data(contentsOf: Analytics.Service.filepath) else { return [] }
            let events = (try? JSONDecoder().decode([Analytics.Event].self, from: eventsData)) ?? []
            return events.sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        internal static func record(event: Analytics.Event) {
            Analytics.Service.record(events: [event])
        }
        
        internal static func record(events: [Analytics.Event]) {
            Analytics.queue.async {
                var tmpEvents = Analytics.Service.loadEvents()
                tmpEvents.append(contentsOf: events)
                let sortedEvents = tmpEvents.sorted(by: { $0.createdAt < $1.createdAt })
                try? Analytics.Service.save(events: sortedEvents)
            }
        }
        
        private static func save(events: [Analytics.Event]) throws {
            let eventsData = try JSONEncoder().encode(events)
            try eventsData.write(to: Analytics.Service.filepath)
        }
        
        internal static func deleteEvents(_ events: [Analytics.Event]? = nil) throws {
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
                
                var storedEvents = Analytics.Service.loadEvents()
                if storedEvents.count > batchSize {
                    storedEvents = Array(storedEvents[0..<Int(batchSize)])
                }
                
                let analyticsUrlStrs: [String?] = Array(Set(storedEvents.map({ $0.analyticsUrl })))
                
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
                    
                    let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
                    client.sendAnalyticsEvent(url: url, body: requestBody) { result in
                        switch result {
                        case .success:
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
                                Analytics.Service.sync()
                            }
                            
                        case .failure(let err):
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

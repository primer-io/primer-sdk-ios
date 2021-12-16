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
        
        static var isSyncAllowed: Bool {
            guard let lastSyncedAt = Analytics.Service.lastSyncAt else { return true }
            return lastSyncedAt.addingTimeInterval(10) < Date()
        }
        
        private static func loadEvents() -> [Event] {
            guard let eventsData = try? Data(contentsOf: Analytics.Service.filepath) else { return [] }
            
            let aes = AES256()
            let deryptedEventsData = (try? aes.decrypt(eventsData)) ?? eventsData
            
            let events = (try? JSONDecoder().decode([Analytics.Event].self, from: deryptedEventsData)) ?? []
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
            let aes = AES256()
            let encryptedEventsData = try aes.encrypt(eventsData)
            try encryptedEventsData.write(to: Analytics.Service.filepath)
        }
        
        internal static func deleteEvents(_ events: [Analytics.Event]? = nil) throws {
            if let events = events {
                let eventsIds = events.compactMap({ $0.localId })
                let allEvents = Analytics.Service.loadEvents()
                let remainingEvents = allEvents.filter({ !eventsIds.contains($0.localId ?? "") })
                try? save(events: remainingEvents)
            } else {
                try? Analytics.Service.save(events: [])
            }
        }
        
        internal static func sync(enforce: Bool = false, batchSize: UInt = 50) {
            if !enforce && !isSyncAllowed { return }
                        
            Analytics.queue.async {
                var storedEvents = Array(Analytics.Service.loadEvents()[0..<Int(batchSize)])
                for (i, _) in storedEvents.enumerated() {
                    storedEvents[i].localId = nil
                }
                
                let analyticsUrl = URL(string: "https://us-central1-primerdemo-8741b.cloudfunctions.net/api/analytics/\(Primer.shared.sdkSessionId)")!
                
                let requestBody = Analytics.Service.Request(data: storedEvents)
                
                let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
                client.sendAnalyticsEvent(url: analyticsUrl, body: requestBody) { result in
                    switch result {
                    case .success:
                        try? Analytics.Service.deleteEvents(storedEvents)
                        self.lastSyncAt = Date()
                        
                        let remainingEvents = Analytics.Service.loadEvents()
                        if !remainingEvents.isEmpty {
                            Analytics.Service.sync(enforce: true)
                        }
                        
                    case .failure(let err):
                        break
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

//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

#if canImport(UIKit)

import Foundation

var called: Int = 0
var numberOfEvents: Int = 0

extension Analytics {
    
    internal class Service {
        static var filepath: URL = {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("reporting")
        }()
        
        static var lastSyncAt: Date? {
            guard let lastSyncAtStr = UserDefaults.standard.string(forKey: "primer.reporting.lastSyncAt") else { return nil }
            guard let lastSyncAt = lastSyncAtStr.toDate() else { return nil }
            return lastSyncAt
        }
        
        static var isSyncAllowed: Bool {
            return true
        }
                
        init() {
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(self, selector: #selector(onTerminate), name: UIApplication.willTerminateNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(onTerminate), name: UIApplication.willResignActiveNotification, object: nil)
        }
        
        @objc
        private func onTerminate() {
            Analytics.Service.sync(enforce: true)
        }
        
        private static func loadEvents() -> [Event] {
            guard let eventsData = try? Data(contentsOf: Analytics.Service.filepath) else { return [] }
            
//            let aes = AES256()
//            guard let deryptedEventsData = try? aes.decrypt(encryptedEventsData) else {
//                return []
//            }
            
            let events = (try? JSONDecoder().decode([Analytics.Event].self, from: eventsData)) ?? []
            return events.sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        internal static func record(event: Analytics.Event) {
            Analytics.Service.record(events: [event])
        }
        
        internal static func record(events: [Analytics.Event]) {
            numberOfEvents += events.count
            called += 1
            print(" *** Called: \(called), totalEvents: \(numberOfEvents)")
            
            let analyticsQueue = DispatchQueue(label: "primer.analytics", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
            
            analyticsQueue.sync {
                // First load events
                var tmpEvents = Analytics.Service.loadEvents()
                
                // Merge them
                tmpEvents.append(contentsOf: events)
                
                // Sort them
                let sortedEvents = tmpEvents.sorted(by: { $0.createdAt < $1.createdAt })
                
                try? Analytics.Service.save(events: sortedEvents)
            }
        }
        
        private static func save(events: [Analytics.Event]) throws {
            let eventsData = try JSONEncoder().encode(events)
//            let aes = AES256()
//            let encryptedEventsData = try aes.encrypt(eventsData)
            try eventsData.write(to: Analytics.Service.filepath)
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
            
            let analyticsQueue = DispatchQueue(label: "primer.analytics", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
            
            analyticsQueue.sync {
                var storedEvents = Analytics.Service.loadEvents()
                for (i, _) in storedEvents.enumerated() {
                    storedEvents[i].localId = nil
                }
                
                let analyticsUrl = URL(string: "https://us-central1-primerdemo-8741b.cloudfunctions.net/api/analytics/\(Primer.shared.sdkSessionId)")!
                
                let requestBody = Analytics.Service.Request(data: storedEvents)
                
                let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
                client.sendAnalyticsEvent(url: analyticsUrl, body: requestBody) { result in
                    try? Analytics.Service.deleteEvents(storedEvents)
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

extension PrimerAPI {
//    case gen
}

#endif

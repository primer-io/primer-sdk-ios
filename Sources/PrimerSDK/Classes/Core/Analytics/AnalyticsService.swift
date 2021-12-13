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
            guard let encryptedEventsData = try? Data(contentsOf: Analytics.Service.filepath) else { return [] }
            
            let aes = AES256()
            guard let deryptedEventsData = try? aes.decrypt(encryptedEventsData) else {
                return []
            }
            
            guard let events = try? JSONDecoder().decode([Analytics.Event].self, from: deryptedEventsData) else {
                return []
            }

            return events.unique(map: { $0.checkoutSessionId }).sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        internal static func record(event: Analytics.Event) {
            Analytics.Service.record(events: [event])
        }
        
        internal static func record(events: [Analytics.Event]) {
            // First load events
            var tmpEvents = Analytics.Service.loadEvents()
            
            // Merge them
            tmpEvents.append(contentsOf: events)
            
            // Make sure they are unique
            let uniqueEvents = tmpEvents.unique(map: { $0.checkoutSessionId })
            
            // Remove synced events
            let filteredEvents = uniqueEvents.filter({ $0.isSynced == false })
            
            // Sort them
            let sortedEvents = filteredEvents.sorted(by: { $0.createdAt < $1.createdAt })
            
            try? Analytics.Service.save(events: sortedEvents)
        }
        
        private static func save(events: [Analytics.Event]) throws {
            let eventsData = try JSONEncoder().encode(events)
            let aes = AES256()
            let encryptedEventsData = try aes.encrypt(eventsData)
            try encryptedEventsData.write(to: Analytics.Service.filepath)
        }
        
        internal static func sync(enforce: Bool = false, batchSize: UInt = 50) {
            if !enforce && !isSyncAllowed { return }

            let storedEvents = Analytics.Service.loadEvents()
            let isSuccess = false
            let queue = DispatchQueue(label: "primer.reporting", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)

            let firstBatch = storedEvents
            let firstBatchIds = firstBatch.compactMap({ $0.clientSessionId })
            queue.async {
                if isSuccess {
                    for var e in storedEvents {
                        if !firstBatchIds.contains(e.clientSessionId ?? "") { continue }
                        e.isSynced = true
                    }

                    let remainingEvents = storedEvents.filter({ $0.isSynced == false })

                    if remainingEvents.isEmpty { return }
                    try! Analytics.Service.save(events: remainingEvents)
                    Analytics.Service.sync(enforce: enforce, batchSize: batchSize)
                }
            }
        }
    }
}

#endif

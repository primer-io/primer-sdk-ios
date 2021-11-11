//
//  Reporting.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/11/21.
//

import Foundation

class Analytics {
    
    struct Event: Codable {
        
        enum Action: Codable {
            case tap
            case other(rawValue: String)
        }
        
        enum Object: String, Codable {
            case textField
        }
        
        var action: Analytics.Event.Action
        var object: Analytics.Event.Object?
        var endUserId: String?
        var objectId: String?
        var objectClass: String?
        var paymentId: String?
        var place: String?
        var primerAccountId: String?
        var properties: [String: String]?
        var sessionId: String?
        
        var timestamp: Date
        
        let clientEventId: String = String.randomString(length: 16)         // Do not include in JSON
        var isSynced: Bool = false  // Do not include in JSON
        
        init(
            action: Analytics.Event.Action,
            object: Analytics.Event.Object?,
            endUserId: String?,
            objectId: String?,
            objectClass: String?,
            paymentId: String?,
            place: String?,
            primerAccountId: String?,
            properties: [String: String]?,
            sessionId: String?
        ) {
            self.action = action
            self.object = object
            self.endUserId = endUserId
            self.objectId = objectId
            self.objectClass = objectClass
            self.paymentId = paymentId
            self.place = place
            self.primerAccountId = primerAccountId
            self.properties = properties
            self.sessionId = sessionId
            
            self.timestamp = Date()
        }
    }
    
    public class Service {
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

            return events.unique(map: { $0.clientEventId }).sorted(by: { $0.timestamp > $1.timestamp })
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
            let uniqueEvents = tmpEvents.unique(map: { $0.clientEventId })
            
            // Remove synced events
            let filteredEvents = uniqueEvents.filter({ $0.isSynced == false })
            
            // Sort them
            let sortedEvents = filteredEvents.sorted(by: { $0.timestamp < $1.timestamp })
            
            try? Analytics.Service.save(events: sortedEvents)
            
            Analytics.Service.sync()
        }
        
        private static func save(events: [Analytics.Event]) throws {
            let eventsData = try JSONEncoder().encode(events)
            let aes = AES256()
            let encryptedEventsData = try aes.encrypt(eventsData)
            try encryptedEventsData.write(to: Analytics.Service.filepath)
        }
        
        private static func sync(enforce: Bool = false, batchSize: UInt = 50) {
//            if !enforce && !isSyncAllowed { return }
//
//            let storedEvents = Reporting.Service.loadEvents()
//            let isSuccess = true
//            let queue = DispatchQueue(label: "primer.reporting", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
//
//            let firstBatch = storedEvents
//            let firstBatchIds = firstBatch.compactMap({ $0.clientEventId })
//            queue.async {
//                if isSuccess {
//                    for var e in storedEvents {
//                        if !firstBatchIds.contains(e.clientEventId) { continue }
//                        e.isSynced = true
//                    }
//
//                    let remainingEvents = storedEvents.filter({ $0.isSynced == false })
//
//                    if remainingEvents.isEmpty { return }
//                    try! Reporting.Service.save(events: remainingEvents)
//                    Reporting.Service.sync(enforce: enforce, batchSize: batchSize)
//                }
//            }
        }
    }
}

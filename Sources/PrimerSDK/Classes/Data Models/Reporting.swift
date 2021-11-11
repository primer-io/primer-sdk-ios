//
//  Reporting.swift
//  PrimerSDK
//
//  Created by Evangelos on 9/11/21.
//

import Foundation

class Reporting {
    
    struct Event: Codable {
        
        enum Name: Codable {
            case test
            case other(rawValue: String)
        }
        
        var name: Reporting.Event.Name
        var timestamp: Date
        
        var localId: String = String.randomString(length: 16)         // Do not include in JSON
        var isSynced: Bool = false  // Do not include in JSON
        
        init(name: Reporting.Event.Name, data: [String: String]) {
            self.localId = "id"
            self.name = name
            self.timestamp = Date()
        }
    }
    
    public class Service {
        
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
            Reporting.Service.sync(enforce: true)
        }
        
        private static func loadEvents() -> [Event] {
            let encryptedData = Data()
            let decryptedData = encryptedData.decrypted
            let jsonStr = String(data: decryptedData, encoding: .utf8)
            let jsonData = try! JSONSerialization.data(withJSONObject: jsonStr, options: .fragmentsAllowed)
            let events = try! JSONDecoder().decode([Event].self, from: jsonData)
            return events
        }
        
        private static var storedEvents: [Event] {
            // First load events
            let storedEvents = Reporting.Service.loadEvents()
            
            // Make sure they are unique
            let uniqueEvents = storedEvents
            
            // Remove synced events
            let filteredEvents = uniqueEvents.filter({ $0.isSynced == false })
            
            // Sort them
            let sortedEvents = filteredEvents.sorted(by: { $0.timestamp < $1.timestamp })
            
            return sortedEvents
        }
        
        internal static func record(event: Reporting.Event) {
            Reporting.Service.record(events: [event])
        }
        
        internal static func record(events: [Reporting.Event]) {
            // First load events
            var storedEvents = Reporting.Service.storedEvents
            
            // Merge them
            storedEvents.append(contentsOf: events)
            
            // Make sure they are unique
            let uniqueEvents = storedEvents
            
            // Remove synced events
            let filteredEvents = uniqueEvents.filter({ $0.isSynced == false })
            
            // Sort them
            let sortedEvents = filteredEvents.sorted(by: { $0.timestamp < $1.timestamp })
            
            try? Reporting.Service.save(events: sortedEvents)
            
            Reporting.Service.sync()
        }
        
        private static func save(events: [Reporting.Event]) throws {
            let jsonData = try JSONSerialization.data(withJSONObject: events, options: .fragmentsAllowed)
            let jsonStr = String(data: jsonData, encoding: .utf8)!
            let encryptedStr = jsonStr.encrypted
            let encryptedData = encryptedStr.data(using: .utf8)
            try encryptedData?.save(to: URL(string: "")!)
        }
        
        private static func sync(enforce: Bool = false, batchSize: UInt = 50) {
            if !enforce && !isSyncAllowed { return }
            
            let storedEvents = Reporting.Service.storedEvents
            let isSuccess = true
            let queue = DispatchQueue(label: "primer.reporting", qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
            
            let firstBatch = storedEvents
            let firstBatchIds = firstBatch.compactMap({ $0.localId })
            queue.async {
                if isSuccess {
                    for var e in storedEvents {
                        if !firstBatchIds.contains(e.localId) { continue }
                        e.isSynced = true
                    }

                    let remainingEvents = storedEvents.filter({ $0.isSynced == false })
                    
                    if remainingEvents.isEmpty { return }
                    try! Reporting.Service.save(events: remainingEvents)
                    Reporting.Service.sync(enforce: enforce, batchSize: batchSize)
                }
            }
        }
    }
}

extension String {
    var encrypted: String {
        return ""
    }
}

extension Data {
    
    var decrypted: Data {
        return Data()
    }
    
    func save(to file: URL) throws {
        
    }
    
}

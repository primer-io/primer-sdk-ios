//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//



import Foundation

extension Analytics {
    
    internal class Service {
        
        static var filepath: URL = {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("analytics")
            Primer.shared.logger?.debug(message: "Analytics URL:\n\(url)\n")
            return url
        }()
        
        static let sdkLogsUrl = URL(string: "https://analytics.production.data.primer.io/sdk-logs")!
        
        @discardableResult
        internal static func record(event: Analytics.Event) -> Promise<Void> {
            Analytics.Service.record(events: [event])
        }
        
        @discardableResult
        internal static func record(events: [Analytics.Event]) -> Promise<Void> {
            return Promise { seal in
                Analytics.queue.async {
                    Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 Recording \(events.count) events")
                    
                    do {
                        let storedEvents: [Analytics.Event] = try Analytics.Service.loadEventsSynchronously()
                        
                        let storedEventsIds = storedEvents.compactMap({ $0.localId })
                        var eventsToAppend: [Analytics.Event] = []
                        
                        for event in events {
                            if storedEventsIds.contains(event.localId) { continue }
                            eventsToAppend.append(event)
                        }
                        
                        var combinedEvents: [Analytics.Event] = eventsToAppend.sorted(by: { $0.createdAt > $1.createdAt })
                        combinedEvents.append(contentsOf: storedEvents)
                        Analytics.Service.saveSynchronously(events: combinedEvents)
                        
                        seal.fulfill()
                        
                    } catch {
                        seal.reject(error)
                    }
                }
            }
        }
        
        @discardableResult
        internal static func sync(batchSize: UInt = 300) -> Promise<Void> {
            return Promise { seal in
                Analytics.queue.async {
                    Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 Syncing...")
                    
                    let promises: [Promise<Void>] = [
                        Analytics.Service.sendSkdLogEvents(batchSize: batchSize),
                        Analytics.Service.sendSkdAnalyticsEvents(batchSize: batchSize)
                    ]
                                        
                    firstly {
                        when(fulfilled: promises)
                    }
                    .done { responses in
                        Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 All events synced...")

                    }
                    .ensure {
                        let remainingEvents = try? self.loadEventsSynchronously()
                        Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 Deleted synced events. There're \((remainingEvents ?? []).count) events remaining in the queue.")
                        seal.fulfill()
                        
                    }
                    .catch { err in
                        Primer.shared.logger?.error(message: "📚 ANALYTICS\n📚 Failed to sync events with error \(err.localizedDescription)")
                        seal.reject(err)
                    }
                }
            }
        }
        
        private static func sendSkdLogEvents(batchSize: UInt) -> Promise<Void> {
            return Promise { seal in
                do {
                    let storedEvents = try Analytics.Service.loadEventsSynchronously()
                    let sdkLogEvents = storedEvents.filter({ $0.analyticsUrl == nil })
                    let sdkLogEventsBatches = sdkLogEvents.toBatches(of: batchSize)
                    
                    var promises: [Promise<Void>] = []
                    
                    for sdkLogEventsBatch in sdkLogEventsBatches {
                        let p = Analytics.Service.sendEvents(sdkLogEventsBatch, to: Analytics.Service.sdkLogsUrl)
                        promises.append(p)
                    }
                    
                    firstly {
                        when(fulfilled: promises)
                    }
                    .done {
                        seal.fulfill()
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                    
                } catch {
                    seal.reject(error)
                }
            }
        }
        
        private static func sendSkdAnalyticsEvents(batchSize: UInt) -> Promise<Void> {
            return Promise { seal in
                do {
                    let storedEvents = try Analytics.Service.loadEventsSynchronously()
                    let analyticsEvents = storedEvents.filter({ $0.analyticsUrl != nil })
                    let analyticsEventsBatches = analyticsEvents.toBatches(of: batchSize)
                    
                    var promises: [Promise<Void>] = []
                    
                    if let analyticsUrlStr = analyticsEvents.first(where: { $0.analyticsUrl != nil })?.analyticsUrl,
                       let analyticsUrl = URL(string: analyticsUrlStr)
                    {
                        for analyticsEventsBatch in analyticsEventsBatches {
                            let p = sendEvents(analyticsEventsBatch, to: analyticsUrl)
                            promises.append(p)
                        }
                        
                        firstly {
                            when(fulfilled: promises)
                        }
                        .done {
                            seal.fulfill()
                        }
                        .catch { err in
                            seal.reject(err)
                        }
                        
                    } else {
                        seal.fulfill()
                    }
                    
                } catch {
                    seal.reject(error)
                }
            }
        }
        
        private static func sendEvents(
            _ events: [Analytics.Event],
            to url: URL
        ) -> Promise<Void> {
            return Promise { seal in
                Analytics.Service.sendEvents(events, to: url) { err in
                    if let err = err {
                        seal.reject(err)
                    } else {
                        seal.fulfill()
                    }
                }
            }
        }
        
        private static func sendEvents(
            _ events: [Analytics.Event],
            to url: URL,
            completion: @escaping (Error?) -> Void
        ) {
            if events.isEmpty {
                completion(nil)
                return
            }
            
            if url.absoluteString != Analytics.Service.sdkLogsUrl.absoluteString, PrimerAPIConfigurationModule.clientToken?.decodedJWTToken == nil
            {
                // Sync another time
                completion(nil)
                return
            }
            
            let decodedJWTToken = PrimerAPIConfigurationModule.clientToken?.decodedJWTToken
            
            let apiClient: PrimerAPIClientProtocol = Analytics.apiClient ?? PrimerAPIClient()
            apiClient.sendAnalyticsEvents(
                clientToken: decodedJWTToken,
                url: url,
                body: events
            ) { result in
                switch result {
                case .success:
                    Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 Finished syncing \(events.count) events on URL: \(url.absoluteString)")
                    Analytics.Service.deleteEventsSynchronously(events)
                    
                    completion(nil)
                    
                case .failure(let err):
                    Primer.shared.logger?.error(message: "📚 ANALYTICS\n📚 Failed to sync \(events.count) events on URL \(url.absoluteString) with error \(err)")
                    ErrorHandler.handle(error: err)
                    completion(err)
                }
            }
        }
        
        internal static func loadEventsSynchronously() throws -> [Analytics.Event] {
            do {
                Primer.shared.logger?.error(message: "📚 ANALYTICS\n📚 Loading events")
                
                if #available(iOS 16.0, *) {
                    if !FileManager.default.fileExists(atPath: Analytics.Service.filepath.path()) {
                        return []
                    }
                } else {
                    if !FileManager.default.fileExists(atPath: Analytics.Service.filepath.path) {
                        return []
                    }
                }
                
                let eventsData = try Data(contentsOf: Analytics.Service.filepath)
                let events = try JSONDecoder().decode([Analytics.Event].self, from: eventsData)
                let sortedEvents = events.sorted(by: { $0.createdAt > $1.createdAt })
                return sortedEvents
                
            } catch {
                Analytics.Service.deleteAnalyticsFile()
                return []
            }
        }
        
        private static func saveSynchronously(events: [Analytics.Event]) {
            DispatchQueue.global(qos: .utility).sync {
                Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 Saving \(events.count) events")
                
                do {
                    let eventsData = try JSONEncoder().encode(events)
                    try eventsData.write(to: Analytics.Service.filepath)
                    
                } catch {
                    Primer.shared.logger?.error(message: "📚 ANALYTICS\n📚 \(error.localizedDescription)")
                }
            }
        }
        
        internal static func deleteEventsSynchronously(_ events: [Analytics.Event]? = nil)  {
            Analytics.queue.sync {
                Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 Deleting \(events == nil ? "all" : "\(events!.count)") events")
                
                do {
                    if let events = events {
                        let storedEvents = try Analytics.Service.loadEventsSynchronously()
                        let eventsLocalIds = events.compactMap({ $0.localId })
                        let remainingEvents = storedEvents.filter({ !eventsLocalIds.contains($0.localId )} )
                        Analytics.Service.saveSynchronously(events: remainingEvents)
                    } else {
                        Analytics.Service.deleteAnalyticsFile()
                    }
                } catch {
                    Primer.shared.logger?.error(message: "📚 ANALYTICS\n📚 Failed to save partial events before deleting file. Deleting file anyway.")
                    Analytics.Service.deleteAnalyticsFile()
                }
            }
        }
        
        internal static func deleteAnalyticsFile() {
            Primer.shared.logger?.debug(message: "📚 ANALYTICS\n📚 Deleting analytics file at \(Analytics.Service.filepath.absoluteString)")
            
            if #available(iOS 16.0, *) {
                if FileManager.default.fileExists(atPath: Analytics.Service.filepath.path()) {
                    do {
                        try FileManager.default.removeItem(at: Analytics.Service.filepath)
                        
                    } catch {
                        let err = PrimerError.underlyingErrors(
                            errors: [error],
                            userInfo: nil,
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                    }
                }
            } else {
                if FileManager.default.fileExists(atPath: Analytics.Service.filepath.path) {
                    do {
                        try FileManager.default.removeItem(at: Analytics.Service.filepath)
                        
                    } catch {
                        let err = PrimerError.underlyingErrors(
                            errors: [error],
                            userInfo: nil,
                            diagnosticsId: UUID().uuidString)
                        ErrorHandler.handle(error: err)
                    }
                }
            }
            
        }
        
        struct Response: Decodable {
            let id: String?
            let result: String?
        }
    }
}



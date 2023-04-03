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
        
        static let sdkLogsUrl = URL(string: "https://analytics.production.data.primer.io/sdk-logs")!
        
        @discardableResult
        internal static func record(event: Analytics.Event) -> Promise<Void> {
            Analytics.Service.record(events: [event])
        }
        
        @discardableResult
        internal static func record(events: [Analytics.Event]) -> Promise<Void> {
            return Promise { seal in
                Analytics.queue.async {
                    primerLogAnalytics(
                        title: "ANALYTICS",
                        message: "📚 Recording \(events.count) events",
                        prefix: "📚",
                        bundle: Bundle.primerFrameworkIdentifier,
                        file: #file,
                        className: "\(Self.self)",
                        function: #function,
                        line: #line)
                    
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
                    primerLogAnalytics(
                        title: "ANALYTICS",
                        message: "📚 Syncing...",
                        prefix: "📚",
                        bundle: Bundle.primerFrameworkIdentifier,
                        file: #file, className: "\(Self.self)",
                        function: #function,
                        line: #line)
                    
                    let promises: [Promise<Void>] = [
                        Analytics.Service.sendSkdLogEvents(batchSize: batchSize),
                        Analytics.Service.sendSkdAnalyticsEvents(batchSize: batchSize)
                    ]
                                        
                    firstly {
                        when(fulfilled: promises)
                    }
                    .done { responses in
                        primerLogAnalytics(
                            title: "ANALYTICS",
                            message: "📚 All events synced",
                            prefix: "📚",
                            bundle: Bundle.primerFrameworkIdentifier,
                            file: #file, className: "\(Self.self)",
                            function: #function,
                            line: #line)
                    }
                    .ensure {
                        let remainingEvents = try? self.loadEventsSynchronously()
                        primerLogAnalytics(
                            title: "ANALYTICS",
                            message: "📚 Deleted synced events. There're \((remainingEvents ?? []).count) events remaining in the queue.",
                            prefix: "📚",
                            bundle: Bundle.primerFrameworkIdentifier,
                            file: #file, className: "\(Self.self)",
                            function: #function,
                            line: #line)
                        
                        seal.fulfill()
                        
                    }
                    .catch { err in
                        primerLogAnalytics(
                            title: "ANALYTICS",
                            message: "📚 Failed to sync events with error \(err.localizedDescription)",
                            prefix: "📚",
                            bundle: Bundle.primerFrameworkIdentifier,
                            file: #file, className: "\(Self.self)",
                            function: #function,
                            line: #line)
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
                        Analytics.Service.deleteEventsSynchronously(events)
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
                    primerLogAnalytics(
                        title: "ANALYTICS",
                        message: "📚 Finished syncing \(events.count) events on URL: \(url.absoluteString)",
                        prefix: "📚",
                        bundle: Bundle.primerFrameworkIdentifier,
                        file: #file,
                        className: "\(Self.self)",
                        function: #function,
                        line: #line)
                    
                    completion(nil)
                    
                case .failure(let err):
                    primerLogAnalytics(
                        title: "ANALYTICS",
                        message: "📚 Failed to sync \(events.count) events on URL \(url.absoluteString) with error \(err)",
                        prefix: "📚",
                        bundle: Bundle.primerFrameworkIdentifier,
                        file: #file, className: "\(Self.self)",
                        function: #function,
                        line: #line)
                    ErrorHandler.handle(error: err)
                    completion(err)
                }
            }
        }
        
        internal static func loadEventsSynchronously() throws -> [Analytics.Event] {
            primerLogAnalytics(
                title: "ANALYTICS",
                message: "📚 Loading events",
                prefix: "📚",
                bundle: Bundle.primerFrameworkIdentifier,
                file: #file, className: "\(Self.self)",
                function: #function,
                line: #line)
            
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
        }
        
        private static func saveSynchronously(events: [Analytics.Event]) {
            DispatchQueue.global(qos: .utility).sync {
                primerLogAnalytics(
                    title: "ANALYTICS",
                    message: "📚 Saving \(events.count) events",
                    prefix: "📚",
                    bundle: Bundle.primerFrameworkIdentifier,
                    file: #file,
                    className: "\(Self.self)",
                    function: #function,
                    line: #line)
                
                do {
                    let eventsData = try JSONEncoder().encode(events)
                    try eventsData.write(to: Analytics.Service.filepath)
                    
                } catch {
                    primerLogAnalytics(
                        title: "ANALYTICS",
                        message: error.localizedDescription,
                        prefix: "📚",
                        bundle: Bundle.primerFrameworkIdentifier,
                        file: #file, className: "\(Self.self)",
                        function: #function,
                        line: #line)
                }
            }
        }
        
        internal static func deleteEventsSynchronously(_ events: [Analytics.Event]? = nil)  {
            Analytics.queue.sync {
                primerLogAnalytics(
                    title: "ANALYTICS",
                    message: "📚 Deleting \(events == nil ? "all" : "\(events!.count)") events",
                    prefix: "📚",
                    bundle: Bundle.primerFrameworkIdentifier,
                    file: #file, className: "\(Self.self)",
                    function: #function,
                    line: #line)
                
                do {
                    if let events = events {
                        let storedEvents = try Analytics.Service.loadEventsSynchronously()
                        let eventsLocalIds = events.compactMap({ $0.localId })
                        let remainingEvents = storedEvents.filter({ !eventsLocalIds.contains($0.localId )} )
                        Analytics.Service.saveSynchronously(events: remainingEvents)
                        
                        let newStoredEvents = try Analytics.Service.loadEventsSynchronously()
                        
                    } else {
                        Analytics.Service.deleteAnalyticsFileSynchonously()
                    }
                } catch {
                    Analytics.Service.deleteAnalyticsFileSynchonously()
                }
            }
        }
        
        static func deleteAnalyticsFileSynchonously() {
            Analytics.queue.sync {
                primerLogAnalytics(
                    title: "ANALYTICS",
                    message: "📚 Deleting analytics file at \(Analytics.Service.filepath.absoluteString)",
                    prefix: "📚",
                    bundle: Bundle.primerFrameworkIdentifier,
                    file: #file, className: "\(Self.self)",
                    function: #function,
                    line: #line)
                
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
        }
        
        struct Response: Decodable {
            let id: String?
            let result: String?
        }
    }
}

#endif

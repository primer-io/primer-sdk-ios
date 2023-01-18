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
                let storedEvents = Analytics.Service.loadEvents()
                let eventsLocalIds = events.compactMap({ $0.localId ?? "" })
                
                let remainingEvents = storedEvents.filter({ !eventsLocalIds.contains($0.localId ?? "")} )
                try save(events: remainingEvents)

            } else {
                try Analytics.Service.save(events: [])
            }
        }
        
        internal static func sync(batchSize: UInt = 100) {
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
                
                let sdkLogEvents = storedEvents.filter({ $0.analyticsUrl == nil })
                let analyticsUrls = storedEvents.compactMap({ $0.analyticsUrl }).compactMap({ URL(string: $0) }).unique
                var isFinishedSyncingSdkLogEvents = false
                var isFinishedSyncingAllAnalyticsUrls: [Bool] = analyticsUrls.compactMap({ _ in false })
                
                if !sdkLogEvents.isEmpty, let sdkLogEventsURL = URL(string: "https://analytics.production.data.primer.io/sdk-logs") {
                    let sdkLogEventsRequestBody = Analytics.Service.Request(data: sdkLogEvents)
                    
                    primerLogAnalytics(
                        title: "ANALYTICS",
                        message: "📚 Syncing \(sdkLogEvents.count) events on URL: \(sdkLogEventsURL.absoluteString)",
                        prefix: "📚",
                        bundle: Bundle.primerFrameworkIdentifier,
                        file: #file, className: "\(Self.self)",
                        function: #function,
                        line: #line)
                    
                    let apiClient: PrimerAPIClientProtocol = Analytics.apiClient ?? PrimerAPIClient()
                    apiClient.sendAnalyticsEvents(clientToken: nil, url: sdkLogEventsURL, body: sdkLogEventsRequestBody) { result in
                        Analytics.Event.omitLocalParametersEncoding = false
                        isFinishedSyncingSdkLogEvents = true
                        
                        switch result {
                        case .success:
                            primerLogAnalytics(
                                title: "ANALYTICS",
                                message: "📚 Finished syncing \(sdkLogEvents.count) events on URL: \(sdkLogEventsURL.absoluteString)",
                                prefix: "📚",
                                bundle: Bundle.primerFrameworkIdentifier,
                                file: #file, className: "\(Self.self)",
                                function: #function,
                                line: #line)
                            
                            do {
                                try Analytics.Service.deleteEvents(sdkLogEvents)
                            } catch {
                                ErrorHandler.handle(error: error)
                                return
                            }
                            
                            self.lastSyncAt = Date()
                            
                            if isFinishedSyncingSdkLogEvents &&
                                (isFinishedSyncingAllAnalyticsUrls.filter({ $0 == false }).count == 0)
                            {
                                let remainingEvents = Analytics.Service.loadEvents()
                                    .filter({ $0.eventType != Analytics.Event.EventType.networkCall && $0.eventType != Analytics.Event.EventType.networkConnectivity })
                                if !remainingEvents.isEmpty {
                                    primerLogAnalytics(
                                        title: "ANALYTICS",
                                        message: "📚 \(remainingEvents.count) events remain",
                                        prefix: "📚",
                                        bundle: Bundle.primerFrameworkIdentifier,
                                        file: #file, className: "\(Self.self)",
                                        function: #function,
                                        line: #line)

                                    Analytics.Service.sync()
                                }
                            }
                            
                        case .failure(let err):
                            primerLogAnalytics(
                                title: "ANALYTICS",
                                message: "📚 Failed to sync \(sdkLogEvents.count) events on URL \(sdkLogEventsURL.absoluteString) with error \(err)",
                                prefix: "📚",
                                bundle: Bundle.primerFrameworkIdentifier,
                                file: #file, className: "\(Self.self)",
                                function: #function,
                                line: #line)
                        }
                    }
                }
                
                for (index, analyticsUrl) in analyticsUrls.enumerated() {
                    let analyticsEvents = storedEvents.filter({ $0.analyticsUrl == analyticsUrl.absoluteString })
                    
                    if !analyticsEvents.isEmpty, let decodedJWTToken = PrimerAPIConfigurationModule.clientToken?.decodedJWTToken {
                        let analyticsEventsRequestBody = Analytics.Service.Request(data: analyticsEvents)
                        
                        primerLogAnalytics(
                            title: "ANALYTICS",
                            message: "📚 Syncing \(analyticsEvents.count) events on URL: \(analyticsUrl.absoluteString)",
                            prefix: "📚",
                            bundle: Bundle.primerFrameworkIdentifier,
                            file: #file, className: "\(Self.self)",
                            function: #function,
                            line: #line)
                        
                        let apiClient: PrimerAPIClientProtocol = Analytics.apiClient ?? PrimerAPIClient()
                        apiClient.sendAnalyticsEvents(clientToken: decodedJWTToken, url: analyticsUrl, body: analyticsEventsRequestBody) { result in
                            Analytics.Event.omitLocalParametersEncoding = false
                            isFinishedSyncingAllAnalyticsUrls[index] = true
                            
                            switch result {
                            case .success:
                                primerLogAnalytics(
                                    title: "ANALYTICS",
                                    message: "📚 Finished syncing \(analyticsEvents.count) events on URL: \(analyticsUrl.absoluteString)",
                                    prefix: "📚",
                                    bundle: Bundle.primerFrameworkIdentifier,
                                    file: #file, className: "\(Self.self)",
                                    function: #function,
                                    line: #line)
                                
                                do {
                                    try Analytics.Service.deleteEvents(analyticsEvents)
                                } catch {
                                    ErrorHandler.handle(error: error)
                                    return
                                }
                                
                                self.lastSyncAt = Date()
                                
                                if isFinishedSyncingSdkLogEvents &&
                                    (isFinishedSyncingAllAnalyticsUrls.filter({ $0 == false }).count == 0)
                                {
                                    let remainingEvents = Analytics.Service.loadEvents()
                                        .filter({ $0.eventType != Analytics.Event.EventType.networkCall && $0.eventType != Analytics.Event.EventType.networkConnectivity })
                                    if !remainingEvents.isEmpty {
                                        primerLogAnalytics(
                                            title: "ANALYTICS",
                                            message: "📚 \(remainingEvents.count) events remain",
                                            prefix: "📚",
                                            bundle: Bundle.primerFrameworkIdentifier,
                                            file: #file, className: "\(Self.self)",
                                            function: #function,
                                            line: #line)

                                        Analytics.Service.sync()
                                    }
                                }
                                
                            case .failure(let err):
                                primerLogAnalytics(
                                    title: "ANALYTICS",
                                    message: "📚 Failed to sync \(analyticsEvents.count) events on URL \(analyticsUrl.absoluteString) with error \(err)",
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

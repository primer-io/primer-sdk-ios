//
//  AnalyticsTests+Helpers.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 23/10/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

extension AnalyticsTests {
    
    func corruptAnalyticsFileData() -> Promise<Void> {
        return Promise { seal in
            let randomStr = "random-string"
            
            do {
                let eventsData = randomStr.data(using: .utf8)!
                try eventsData.write(to: storage.fileURL)
                seal.fulfill()
            } catch {
                XCTFail("Failed to write '\(randomStr)' in '\(storage.fileURL.absoluteString)'")
                seal.reject(error)
            }
        }
    }
    
    func createEvents() -> Promise<[Analytics.Event]> {
        return Promise { seal in
            let events = [
                Analytics.Event(
                    eventType: .message,
                    properties: MessageEventProperties(
                        message: "An error message",
                        messageType: .error,
                        severity: .error)),
                Analytics.Event(
                    eventType: .message,
                    properties: MessageEventProperties(
                        message: "An debug message",
                        messageType: .other,
                        severity: .debug)),
                Analytics.Event(
                    eventType: .ui,
                    properties: UIEventProperties(
                        action: .click,
                        context: nil,
                        extra: "Extra",
                        objectType: .button,
                        objectId: .done,
                        objectClass: "PrimerButton",
                        place: .cardForm)),
                Analytics.Event(
                    eventType: .ui,
                    properties: UIEventProperties(
                        action: .dismiss,
                        context: nil,
                        extra: "Extra",
                        objectType: .view,
                        objectId: nil,
                        objectClass: "PrimerViewController",
                        place: .threeDSScreen)),
                Analytics.Event(
                    eventType: .crash,
                    properties: CrashEventProperties(stacktrace: ["Stacktrace item"])),
                Analytics.Event(
                    eventType: .networkCall,
                    properties: NetworkCallEventProperties(
                        callType: .requestStart,
                        id: "id-0",
                        url: "https://url.com",
                        method: .get,
                        errorBody: nil,
                        responseCode: nil)),
                Analytics.Event(
                    eventType: .networkCall,
                    properties: NetworkCallEventProperties(
                        callType: .requestEnd,
                        id: "id-0",
                        url: "https://url.com",
                        method: .get,
                        errorBody: "An error body",
                        responseCode: 500)),
                Analytics.Event(
                    eventType: .networkConnectivity,
                    properties: NetworkConnectivityEventProperties(networkType: .wifi)),
                Analytics.Event(
                    eventType: .sdkEvent,
                    properties: SDKEventProperties(
                        name: "Class.Function",
                        params: [
                            "key1": "val1",
                            "key2": "val2"
                        ]))
            ]
            
            seal.fulfill(events)
        }
    }
    
    func createAnalyticsEvents(deletePreviousEvents: Bool) -> Promise<[Analytics.Event]> {
        return Promise { seal in
            if deletePreviousEvents {
                self.deleteAnalyticsFileSynchonously()
            }
            
            firstly {
                return Analytics.Service.record(events: self.newEvents)
            }
            .done {
                seal.fulfill(self.newEvents)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    func createDemoClientSessionAndSetAppState() -> Promise<String> {
        return Promise { seal in
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                let settings = PrimerSettings()
                DependencyContainer.register(settings as PrimerSettingsProtocol)
                let appState = AppState()
                appState.clientToken = MockAppState.mockClientToken
                DependencyContainer.register(appState as AppStateProtocol)
                seal.fulfill(MockAppState.mockClientToken)
            }
        }
    }
    
    func createEvents(_ numberOfEvents: UInt, withMessage message: String?) -> [Analytics.Event] {
        var events: [Analytics.Event] =  []
        
        for i in 0..<numberOfEvents {
            let e = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "\(message ?? "A message") [\(i)]",
                    messageType: .error,
                    severity: .error))
            events.append(e)
        }
        
        return events
    }
    
    func writeEvents(_ events: [Analytics.Event], fromQueue queue: DispatchQueue, completion: @escaping (() -> Void)) {
        queue.async {
            _ = firstly {
                Analytics.Service.record(events: events)
            }
            .ensure {
                completion()
            }
        }
    }
    
    func createMockAnalyticsFile() {
        do {
            let eventsData = AnalyticsTestsConstants.analyticsEvents.data(using: .utf8)!
            try eventsData.write(to: storage.fileURL)
            
        } catch {
            XCTFail("Failed to create analytics file for RC3 - error message: \(error.localizedDescription)")
        }
    }
    
    func deleteAnalyticsFile(fromQueue queue: DispatchQueue, completion: @escaping (() -> Void)) {
        queue.async {
            self.deleteAnalyticsFileSynchonously()
            completion()
        }
    }
    
    func syncAnalyticsFile(fromQueue queue: DispatchQueue, completion: @escaping (() -> Void)) {
        queue.async {
            firstly {
                Analytics.Service.flush()
            }
            .ensure {
                completion()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
    }
    
    func cleanUpAnalytics() {
        self.deleteAnalyticsFileSynchonously()
        let storedEvents = storage.loadEvents()
        XCTAssert(storedEvents.count == 0, "Analytics events should be empty")
    }
    
    func deleteAnalyticsFileSynchonously() {
        Analytics.Service.clear()
    }
    
    var storage: Analytics.DefaultStorage {
        return _storage
    }
    
    func recreateService() {
        Analytics.Service.shared = {
            Analytics.Service(sdkLogsUrl: Analytics.Service.defaultSdkLogsUrl,
                              batchSize: Analytics.Service.maximumBatchSize,
                              storage: Analytics.storage,
                              apiClient: Analytics.apiClient ?? PrimerAPIClient())
        }()
    }
}

fileprivate let _storage = Analytics.DefaultStorage()

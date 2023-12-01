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
                try eventsData.write(to: Analytics.Service.filepath)
                seal.fulfill()
            } catch {
                XCTFail("Failed to write '\(randomStr)' in '\(Analytics.Service.filepath.absoluteString)'")
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
//            let networking = Networking()
//            networking.requestClientSession(
//                clientSessionRequestBody: ClientSessionRequestBody.demoClientSessionRequestBody) { clientToken, err in
//                    if let err = err {
//                        seal.reject(err)
//                    } else if let clientToken = clientToken {
//                        let settings = PrimerSettings()
//                        DependencyContainer.register(settings as PrimerSettingsProtocol)
//                        let appState = AppState()
//                        appState.clientToken = clientToken
//                        DependencyContainer.register(appState as AppStateProtocol)
//                        seal.fulfill(clientToken)
//                    } else {
//                        fatalError()
//                    }
//                }
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
            firstly {
                Analytics.Service.record(events: events)
            }
            .done {
                
            }
            .ensure {
                completion()
            }
            .catch { _ in
                
            }
        }
    }
    
    func createAnalyticsFileForRC3() {
        do {
            let eventsData = AnalyticsTestsConstants.analytics_v_2_17_0_rc_3_Events.data(using: .utf8)!
            try eventsData.write(to: Analytics.Service.filepath)
            
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
    
    func syncAnalyticsFile(fromQueue queue: DispatchQueue, batchSize: UInt = 100, completion: @escaping (() -> Void)) {
        queue.async {
            firstly {
                Promise<Void> { seal in
                    Analytics.Service.flush()
                    seal.fulfill()
                }
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
        let storedEvents = (try? Analytics.Service.loadEvents()) ?? []
        XCTAssert(storedEvents.count == 0, "Analytics events should be empty")
    }
    
    func deleteAnalyticsFileSynchonously() {
        Analytics.queue.sync {
            Analytics.Service.deleteAnalyticsFile()
        }
    }
}

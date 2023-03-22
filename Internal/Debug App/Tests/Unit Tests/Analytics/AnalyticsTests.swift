//
//  AnalyticsTests.swift
//  Debug App
//
//  Created by Evangelos Pittas on 21/3/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

#if canImport(UIKit)

import XCTest
@testable import PrimerSDK

class AnalyticsTests: XCTestCase {
    
    let newEvents: [Analytics.Event] = [
        Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message",
                messageType: .error,
                severity: .error)),
        Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An analytics message",
                messageType: .analytics,
                severity: .info)),
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
        
    func test_record_new_events() throws {
        let exp = expectation(description: "Await")
        
        var newEvents: [Analytics.Event] = []
        var storedEvents: [Analytics.Event]?
        
        firstly {
            self.createAnalyticsEvents(deletePreviousEvents: true)
        }
        .then { events -> Promise<[Analytics.Event]> in
            newEvents = events
            return self.createAnalyticsEvents(deletePreviousEvents: false)
        }
        .then { events -> Promise<[Analytics.Event]> in
            newEvents.append(contentsOf: events)
            return Analytics.Service.loadEvents()
        }
        .done { events in
            storedEvents = events
            exp.fulfill()
        }
        .catch { err in
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
        
        if newEvents.isEmpty {
            XCTFail("Failed to created new events")
            
        } else if (storedEvents ?? []).isEmpty {
            XCTFail("Failed to load stored events")
            
        } else {
            XCTAssert(newEvents.count == storedEvents!.count, "New events \(newEvents.count), events: \(storedEvents!.count)")
        }
    }
    
    func test_sync() throws {
        let exp = expectation(description: "Await")
        
        var storedEvents: [Analytics.Event]?
        let batchSize: UInt = 4
        
        firstly {
            Analytics.Service.deleteAnalyticsFile()
        }
        .then { () -> Promise<[Analytics.Event]> in
            // Create events without having a client token yet
            self.createEvents()
        }
        .then { events -> Promise<Void> in
            return Analytics.Service.record(events: events)
        }
        .then { () -> Promise<String> in
            self.createDemoClientSession()
        }
        .then { clientToken -> Promise<[Analytics.Event]> in
            AppState.current.clientToken = clientToken
            // Create events now that we have a client token
            return self.createEvents()
        }
        .then { events -> Promise<Void> in
            return Analytics.Service.record(events: events)
        }
        .then { () -> Promise<[Analytics.Event]> in
            return Analytics.Service.loadEvents()
        }
        .then { events -> Promise<Void> in
            print("All events: \(events)")
            return Analytics.Service.sync(batchSize: batchSize)
        }
        .then { () -> Promise<[Analytics.Event]> in
            return Analytics.Service.loadEvents()
        }
        .done { events in
            storedEvents = events
            exp.fulfill()
        }
        .catch { err in
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 300000)
                
        let nonNetworkEvents = storedEvents?.filter({ $0.eventType != .networkCall && $0.eventType != .networkConnectivity })
                
        print(nonNetworkEvents)
        XCTAssert((nonNetworkEvents ?? []).count == 0, "nonNetworkEvents: \(nonNetworkEvents?.count)")
    }
    
    func test_corrupt_analytics_file_data() throws {
        let exp = expectation(description: "Await")

        var newEvents: [Analytics.Event]?
        var storedEvents: [Analytics.Event]?
        
        firstly {
            self.createAnalyticsEvents(deletePreviousEvents: true)
        }
        .then { events -> Promise<Void> in
            newEvents = events
            return self.corruptAnalyticsFileData()
        }
        .then { () -> Promise<[Analytics.Event]> in
            return Analytics.Service.loadEvents()
        }
        .done { events in
            storedEvents = events
            exp.fulfill()
        }
        .catch { err in
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
        
        if (newEvents ?? []).isEmpty {
            XCTFail("Failed to created new events")
            
        } else if storedEvents == nil {
            XCTFail("Failed to load stored events")
            
        } else {
            XCTAssert(storedEvents!.count == 0, "There shouldn't be any stored events. storedEvents.count \(storedEvents)")
        }
    }
    
    func test_delete_analytics_file() throws {
        let exp = expectation(description: "Await")
        
        firstly {
            self.createAnalyticsEvents(deletePreviousEvents: true)
        }
        .then { events -> Promise<Void> in
            return Analytics.Service.deleteAnalyticsFile()
        }
        .done { events in
            exp.fulfill()
        }
        .catch { err in
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
        
        if FileManager.default.fileExists(atPath: Analytics.Service.filepath.path) {
            XCTFail("Failed to delete analytics file at '\(Analytics.Service.filepath.absoluteString)'")
        }
    }
    
    private func corruptAnalyticsFileData() -> Promise<Void> {
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
    
    private func createEvents() -> Promise<[Analytics.Event]> {
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
                        message: "An analytics message",
                        messageType: .analytics,
                        severity: .info)),
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
    
    private func createAnalyticsEvents(deletePreviousEvents: Bool) -> Promise<[Analytics.Event]> {
        return Promise { seal in
            firstly { () -> Promise<Void> in
                if deletePreviousEvents {
                    return Analytics.Service.deleteAnalyticsFile()
                } else {
                    return Promise()
                }
            }
            .then {
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
    
    func createDemoClientSession() -> Promise<String> {
        return Promise { seal in
            let networking = Networking()
            networking.requestClientSession(
                clientSessionRequestBody: ClientSessionRequestBody.demoClientSessionRequestBody) { clientToken, err in
                    if let err = err {
                        seal.reject(err)
                    } else if let clientToken = clientToken {
                        seal.fulfill(clientToken)
                    } else {
                        fatalError()
                    }
                }
        }
    }
}


#endif

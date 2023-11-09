//
//  AnalyticsTests.swift
//  Debug App
//
//  Created by Evangelos Pittas on 21/3/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class AnalyticsTests: XCTestCase {
    
    var newEvents: [Analytics.Event] {
        return [
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
    }
        
    func test_record_new_events() throws {
        self.createAnalyticsFileForRC3()
         
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

            do {
                let storedEvents = try Analytics.Service.loadEventsSynchronously()
                return Promise { seal in
                    seal.fulfill(storedEvents)
                }

            } catch {
                return Promise { seal in
                    seal.reject(error)
                }
            }
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
            do {
                let storedEvents = try Analytics.Service.loadEventsSynchronously()
                return Promise { seal in
                    seal.fulfill(storedEvents)
                }
                
            } catch {
                return Promise { seal in
                    seal.fulfill([])
                }
            }
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
    
    func test_corrupt_analytics_file_with_rc_3_events() throws {
        let createClientSessionExpectation = expectation(description: "Create client session")
        var expectationsToBeFulfilled = [createClientSessionExpectation]
        
        firstly {
            self.createDemoClientSessionAndSetAppState()
        }
        .done { clientToken in
            
        }
        .ensure {
            createClientSessionExpectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 30)
        
        self.cleanUpAnalytics()
        
        self.createAnalyticsFileForRC3()
        
        let writeEventExpectation = expectation(description: "Create client session")
        expectationsToBeFulfilled = [writeEventExpectation]
        
        let newEvents = self.createEvents(10, withMessage: "A message")
        
        firstly {
            Analytics.Service.record(events: newEvents)
        }
        .done {
            
        }
        .ensure {
            writeEventExpectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 30)
        
        var storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == 10, "storedEvents should be 10")
    }
    
    func test_sync() throws {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.sendAnalyticsEventsResult = (Analytics.Service.Response(id: "mock-d", result: "success"), nil)
        Analytics.apiClient = mockApiClient
        
        self.createAnalyticsFileForRC3()
        
        let exp = expectation(description: "Await")
        
        var storedEvents: [Analytics.Event]?
        let batchSize: UInt = 4
        
        self.deleteAnalyticsFileSynchonously()
        
        firstly {
            // Create events without having a client token yet
            self.createEvents()
        }
        .then { events -> Promise<Void> in
            return Analytics.Service.record(events: events)
        }
        .then { () -> Promise<String> in
            self.createDemoClientSessionAndSetAppState()
        }
        .then { clientToken -> Promise<[Analytics.Event]> in
            return self.createEvents()
        }
        .then { events -> Promise<Void> in
            return Analytics.Service.record(events: events)
        }
        .then { () -> Promise<[Analytics.Event]> in
            do {
                let storedEvents = try Analytics.Service.loadEventsSynchronously()
                return Promise { seal in
                    seal.fulfill(storedEvents)
                }
                
            } catch {
                return Promise { seal in
                    seal.reject(error)
                }
            }
        }
        .then { events -> Promise<Void> in
            return Analytics.Service.sync(batchSize: batchSize)
        }
        .then { () -> Promise<[Analytics.Event]> in
            do {
                let storedEvents = try Analytics.Service.loadEventsSynchronously()
                return Promise { seal in
                    seal.fulfill(storedEvents)
                }
                
            } catch {
                return Promise { seal in
                    seal.reject(error)
                }
            }
        }
        .done { events in
            storedEvents = events
            exp.fulfill()
        }
        .catch { err in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 600)
                
        let nonNetworkEvents = storedEvents?.filter({ $0.eventType != .networkCall && $0.eventType != .networkConnectivity })
        XCTAssert((nonNetworkEvents ?? []).count == 0, "nonNetworkEvents: \(nonNetworkEvents?.count)")
    }
    
    func test_delete_analytics_file() throws {
        self.createAnalyticsFileForRC3()
        
        let exp = expectation(description: "Await")
        
        firstly {
            self.createAnalyticsEvents(deletePreviousEvents: true)
        }
        .done { events in
            self.deleteAnalyticsFileSynchonously()
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
    
    func test_wrapped_error() throws {
        let recordEvent = expectation(description: "Record event")
        
        self.cleanUpAnalytics()
        
        let diagnosticsId = "diagnostics-id"

        let nsErrorUserInfo: [String: Any] = [
            "nsTestString": "test",
            "nsTestNumber": -3.14,
            "nsTestBoolean": true
        ]
        
        let errorUserInfo: [String: String] = [
            "testString": "test"
        ]
        
        let nsError = NSError(
            domain: "domain",
            code: 1,
            userInfo: nsErrorUserInfo)
        
        let primer3DSErrorContainer = Primer3DSErrorContainer.underlyingError(
            userInfo: errorUserInfo,
            diagnosticsId: diagnosticsId,
            error: nsError)
                
        ErrorHandler.handle(error: primer3DSErrorContainer)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            recordEvent.fulfill()
        }
        
        wait(for: [recordEvent], timeout: 10)
        
        let events = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        let errorEvents = events.filter({ ($0.properties as? MessageEventProperties)?.diagnosticsId == diagnosticsId })
        let errorEvent = errorEvents.first
        
        XCTAssert(errorEvent != nil, "Should had written the error event")
        XCTAssert(errorEvent?.properties as? MessageEventProperties != nil, "Error should contain MessageEventProperties")

        XCTAssert(errorEvent?.appIdentifier == "com.primerapi.PrimerSDKExample", "App identifier should be 'com.primerapi.PrimerSDKExample'")
        XCTAssert(errorEvent?.eventType == .message, "Event type should be '.message'")
        XCTAssert(errorEvent?.sdkType == "IOS_NATIVE", "SDK type should be 'IOS_NATIVE'")

        let errorEventProperties = errorEvent?.properties as? MessageEventProperties
        XCTAssert(errorEventProperties!.diagnosticsId == diagnosticsId, "Error's diagnostic id should be \(diagnosticsId)")
        XCTAssert(errorEventProperties!.context?["threeDsSdkProvider"] as? String == "NETCETERA", "Context should include 'NETCETERA' as threeDsSdkProvider")
        XCTAssert(errorEventProperties!.context?["threeDsWrapperSdkVersion"] as? String != nil, "Context should include threeDsWrapperSdkVersion'")
        XCTAssert(errorEventProperties!.context?["threeDsSdkVersion"] as? String != nil, "Context should include threeDsSdkVersion")
    }
    
    func test_recording_race_conditions() throws {
        self.cleanUpAnalytics()
        self.createAnalyticsFileForRC3()
        var storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == 0, "Analytics events should be empty")
        
        let serialQueue     = DispatchQueue(label: "Serial Queue")
        let concurrentQueue = DispatchQueue(label: "Concurrent Queue", attributes: .concurrent)
        
        let writeEventsOnMainQueueExpectation1 = expectation(description: "Write events on main queue 1")
        let writeEventsOnSerialQueueExpectation1 = expectation(description: "Write events on \(serialQueue.label) 1")
        let writeEventsOnSerialQueueExpectation2 = expectation(description: "Write events on \(serialQueue.label) 2")
        let writeEventsOnConcurrentQueueExpectation1 = expectation(description: "Write events on \(concurrentQueue.label) 1")
        let writeEventsOnConcurrentQueueExpectation2 = expectation(description: "Write events on \(concurrentQueue.label) 2")
        
        // Record events from different queues
        
        var eventsIds: [String] = []
        
        serialQueue.async {
            let e1_1 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 1.1",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e1_1])
            }
            .done {
                eventsIds.append(e1_1.localId)
            }
            .ensure {
                writeEventsOnSerialQueueExpectation1.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        serialQueue.async {
            let e1_2 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 1.2",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e1_2])
            }
            .done {
                eventsIds.append(e1_2.localId)
            }
            .ensure {
                writeEventsOnSerialQueueExpectation2.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        concurrentQueue.async {
            let e2_1 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 2.1",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e2_1])
            }
            .done {
                eventsIds.append(e2_1.localId)
            }
            .ensure {
                writeEventsOnConcurrentQueueExpectation1.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        concurrentQueue.async {
            let e2_2 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 2.2",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e2_2])
            }
            .done {
                eventsIds.append(e2_2.localId)
            }
            .ensure {
                writeEventsOnConcurrentQueueExpectation2.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        let e3 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 3",
                messageType: .error,
                severity: .error))
        
        firstly {
            Analytics.Service.record(events: [e3])
        }
        .done {
            eventsIds.append(e3.localId)
        }
        .ensure {
            writeEventsOnMainQueueExpectation1.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: [
            writeEventsOnMainQueueExpectation1,
            writeEventsOnSerialQueueExpectation1,
            writeEventsOnSerialQueueExpectation2,
            writeEventsOnConcurrentQueueExpectation1,
            writeEventsOnConcurrentQueueExpectation2
        ], timeout: 20)
                
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")
    }
    
    func test_race_conditions_on_recording_and_deleting_events() throws {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.sendAnalyticsEventsResult = (Analytics.Service.Response(id: "mock-d", result: "success"), nil)
        Analytics.apiClient = mockApiClient
        
        self.cleanUpAnalytics()
        self.createAnalyticsFileForRC3()
        var storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        
        self.createAnalyticsFileForRC3()

        let createClientSessionExpectation = expectation(description: "Create client session")
        let expectationsToBeFulfilled = [createClientSessionExpectation]
        
        firstly {
            self.createDemoClientSessionAndSetAppState()
        }
        .done { clientToken in
            createClientSessionExpectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 30)
        
        let serialQueue     = DispatchQueue(label: "Serial Queue")
        let concurrentQueue = DispatchQueue(label: "Concurrent Queue", attributes: .concurrent)
        
        let writeEventsOnMainQueueExpectation1 = expectation(description: "Write events on main queue 1")
        let writeEventsOnSerialQueueExpectation1 = expectation(description: "Write events on \(serialQueue.label) 1")
        let writeEventsOnSerialQueueExpectation2 = expectation(description: "Write events on \(serialQueue.label) 2")
        let writeEventsOnConcurrentQueueExpectation1 = expectation(description: "Write events on \(concurrentQueue.label) 1")
        let writeEventsOnConcurrentQueueExpectation2 = expectation(description: "Write events on \(concurrentQueue.label) 2")
        
        // Record events from different threads/queues
        
        var eventsIds: [String] = []
        
        var e1_1: Analytics.Event!
        var e1_2: Analytics.Event!
        var e2_1: Analytics.Event!
        var e2_2: Analytics.Event!
        var e3: Analytics.Event!
        
        serialQueue.async {
            e1_1 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 1.1",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e1_1])
            }
            .done {
                eventsIds.append(e1_1.localId)
            }
            .ensure {
                writeEventsOnSerialQueueExpectation1.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        serialQueue.async {
            e1_2 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 1.2",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e1_2])
            }
            .done {
                eventsIds.append(e1_2.localId)
            }
            .ensure {
                writeEventsOnSerialQueueExpectation2.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        concurrentQueue.async {
            e2_1 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 2_1",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e2_1])
            }
            .done {
                eventsIds.append(e2_1.localId)
            }
            .ensure {
                writeEventsOnConcurrentQueueExpectation1.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        concurrentQueue.async {
            e2_2 = Analytics.Event(
                eventType: .message,
                properties: MessageEventProperties(
                    message: "An error message 2.2",
                    messageType: .error,
                    severity: .error))
            
            firstly {
                Analytics.Service.record(events: [e2_2])
            }
            .done {
                eventsIds.append(e2_2.localId)
            }
            .ensure {
                writeEventsOnConcurrentQueueExpectation2.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        e3 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 3",
                messageType: .error,
                severity: .error))
        
        firstly {
            Analytics.Service.record(events: [e3])
        }
        .done {
            eventsIds.append(e3.localId)
        }
        .ensure {
            writeEventsOnMainQueueExpectation1.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: [
            writeEventsOnMainQueueExpectation1,
            writeEventsOnSerialQueueExpectation1,
            writeEventsOnSerialQueueExpectation2,
            writeEventsOnConcurrentQueueExpectation1,
            writeEventsOnConcurrentQueueExpectation2
        ], timeout: 20)
                
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        let storedEventsIds = storedEvents.compactMap({ $0.localId })
        
        XCTAssert(storedEventsIds.contains(e1_1.localId),   "Analytics file should contain event \(e1_1.localId)")
        XCTAssert(storedEventsIds.contains(e1_2.localId),   "Analytics file should contain event \(e1_2.localId)")
        XCTAssert(storedEventsIds.contains(e2_2.localId),   "Analytics file should contain event \(e2_2.localId)")
        XCTAssert(storedEventsIds.contains(e3.localId),     "Analytics file should contain event \(e3.localId)")
        XCTAssert(storedEvents.count == eventsIds.count,    "Analytics file should contain \(eventsIds.count) events")

        // Delete events from different queues

        Analytics.Service.deleteEventsSynchronously([e3])
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        var deletedEvent3 = storedEvents.first(where: { $0.localId == e3.localId })
        XCTAssert(deletedEvent3 == nil, "Stored events should not contain event \(deletedEvent3?.localId ?? "n/a")")
        eventsIds = eventsIds.filter({ $0 != e3.localId })

        // Now let's delete different events by dispatching async on the same serial queue

        let deleteEvent1OnSerialQueueExpectation = expectation(description: "Delete event e1_1 on serial queue")
        let deleteEvent2OnSerialQueueExpectation = expectation(description: "Delete event e1_2 on serial queue")

        serialQueue.async {
            Analytics.Service.deleteEventsSynchronously([e1_1])
            eventsIds = eventsIds.filter({ $0 != e1_1.localId })
            deleteEvent1OnSerialQueueExpectation.fulfill()
        }

        serialQueue.async {
            Analytics.Service.deleteEventsSynchronously([e1_2])
            eventsIds = eventsIds.filter({ $0 != e1_2.localId })
            deleteEvent2OnSerialQueueExpectation.fulfill()
        }

        wait(for: [deleteEvent1OnSerialQueueExpectation, deleteEvent2OnSerialQueueExpectation], timeout: 10)

        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []

        var deletedEvent1_1 = storedEvents.first(where: { $0.localId == e1_1.localId })
        var deletedEvent1_2 = storedEvents.first(where: { $0.localId == e1_2.localId })

        XCTAssert(deletedEvent1_1 == nil && deletedEvent1_2 == nil, "Stored events should not contain events \(deletedEvent1_1?.localId ?? "n/a") and \(deletedEvent1_2?.localId ?? "n/a")")

        let storedE2_1 = storedEvents.first(where: { $0.localId == e2_1.localId })
        let storedE2_2 = storedEvents.first(where: { $0.localId == e2_2.localId })
        XCTAssert(storedE2_1 != nil && storedE2_2 != nil, "e2_1 and e2_2 should still be stored")

        // Now let's delete different events by dispatching async on the same concurrent queue

        let deleteEvent1OnConcurrentQueueExpectation = expectation(description: "Delete event e2_1 on concurrent queue")
        let deleteEvent2OnConcurrentQueueExpectation = expectation(description: "Delete event e2_2 on concurrent queue")

        concurrentQueue.async {
            Analytics.Service.deleteEventsSynchronously([e2_1])
            eventsIds = eventsIds.filter({ $0 != e2_1.localId })
            deleteEvent1OnConcurrentQueueExpectation.fulfill()
        }

        concurrentQueue.async {
            Analytics.Service.deleteEventsSynchronously([e2_2])
            eventsIds = eventsIds.filter({ $0 != e2_2.localId })
            deleteEvent2OnConcurrentQueueExpectation.fulfill()
        }

        wait(for: [
            deleteEvent1OnConcurrentQueueExpectation,
            deleteEvent2OnConcurrentQueueExpectation
        ], timeout: 10)

        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []

        var deletedEvent2_1 = storedEvents.first(where: { $0.localId == e2_1.localId })
        var deletedEvent2_2 = storedEvents.first(where: { $0.localId == e2_2.localId })

        XCTAssert(deletedEvent2_1 == nil && deletedEvent2_2 == nil, "Stored events should not contain events \(deletedEvent2_1?.localId ?? "n/a") and \(deletedEvent2_2?.localId ?? "n/a")")
        XCTAssert(storedEvents.isEmpty, "Stored events should be empty")

        // Rewrite some events
        
        let rewriteEventsFromMainQueueExpectation = expectation(description: "Rewrite events from the main queue")
        
        e1_1 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 1.1",
                messageType: .error,
                severity: .error))
        e1_2 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 1.2",
                messageType: .error,
                severity: .error))
        e2_1 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 2.1",
                messageType: .error,
                severity: .error))
        e2_2 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 2.2",
                messageType: .error,
                severity: .error))
        e3 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 3",
                messageType: .error,
                severity: .error))
        
        let events = [e1_1!, e1_2!, e2_1!, e2_2!, e3!]
        
        firstly {
            Analytics.Service.record(events: events)
        }
        .done {
            storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
            eventsIds = events.compactMap({ $0.localId })
        }
        .ensure {
            rewriteEventsFromMainQueueExpectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: [rewriteEventsFromMainQueueExpectation], timeout: 10)
        
        let deleteEvent3OnMainQueueExpectation2       = expectation(description: "Delete event e3 on main queue")
        let deleteEvent1OnSerialQueueExpectation2     = expectation(description: "Delete event e1_1 on serial queue")
        let deleteEvent1OnConcurrentQueueExpectation2 = expectation(description: "Delete event e2_1 on concurrent queue")
        
        serialQueue.async {
            Analytics.Service.deleteEventsSynchronously([e1_1])
            eventsIds = eventsIds.filter({ $0 != e1_1.localId })
            deleteEvent1OnSerialQueueExpectation2.fulfill()
        }
        
        concurrentQueue.async {
            Analytics.Service.deleteEventsSynchronously([e2_1])
            eventsIds = eventsIds.filter({ $0 != e2_1.localId })
            deleteEvent1OnConcurrentQueueExpectation2.fulfill()
        }
        
        // I'm having so much fun, so let's delete an event from the main queue
        
        Analytics.Service.deleteEventsSynchronously([e3])
        deleteEvent3OnMainQueueExpectation2.fulfill()
        eventsIds = eventsIds.filter({ $0 != e3.localId })
        
        
        wait(for: [
            deleteEvent1OnSerialQueueExpectation2,
            deleteEvent1OnConcurrentQueueExpectation2,
            deleteEvent3OnMainQueueExpectation2
        ], timeout: 10)
        
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        deletedEvent1_1 = storedEvents.first(where: { $0.localId == e1_1.localId })
        deletedEvent2_1 = storedEvents.first(where: { $0.localId == e2_1.localId })
        deletedEvent3 = storedEvents.first(where: { $0.localId == e3.localId })
        
        XCTAssert(deletedEvent1_1 == nil && deletedEvent2_1 == nil && deletedEvent3 == nil, "Stored events should not contain events \(deletedEvent1_1?.localId ?? "n/a") and \(deletedEvent2_1?.localId ?? "n/a")")
        XCTAssert(storedEvents.count == eventsIds.count, "Stored events should be empty")
        
        
        // At this point e1_2 and e2_2 are still in the stored events.
        // Test recording a new event (e3), while deleting the other 2

        let writeEvent1OnSerialQueueExpectation3      = expectation(description: "Write event e1_1 on serial queue")
        let writeEvent1OnConcurrentQueueExpectation3  = expectation(description: "Write event e2_1 on concurrent queue")
        let deleteEvent2OnSerialQueueExpectation3     = expectation(description: "Delete event e1_2 on serial queue")
        let deleteEvent2OnConcurrentQueueExpectation3 = expectation(description: "Delete event e2_2 on concurrent queue")

        e1_1 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 1.1",
                messageType: .error,
                severity: .error))
        e2_1 = Analytics.Event(
            eventType: .message,
            properties: MessageEventProperties(
                message: "An error message 2.1",
                messageType: .error,
                severity: .error))
        
        serialQueue.async {
            firstly {
                Analytics.Service.record(events: [e1_1])
            }
            .done {
                eventsIds.append(e1_1.localId)
            }
            .ensure {
                writeEvent1OnSerialQueueExpectation3.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        serialQueue.async {
            Analytics.Service.deleteEventsSynchronously([e1_2])
            eventsIds = eventsIds.filter({ $0 != e1_2.localId })
            deleteEvent2OnSerialQueueExpectation3.fulfill()
        }

        concurrentQueue.async {
            firstly {
                Analytics.Service.record(events: [e2_1])
            }
            .done {
                eventsIds.append(e2_1.localId)
            }
            .ensure {
                writeEvent1OnConcurrentQueueExpectation3.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }
        }
        
        concurrentQueue.async {
            Analytics.Service.deleteEventsSynchronously([e2_2])
            eventsIds = eventsIds.filter({ $0 != e2_2.localId })
            deleteEvent2OnConcurrentQueueExpectation3.fulfill()
        }
        
        wait(for: [
            writeEvent1OnSerialQueueExpectation3,
            writeEvent1OnConcurrentQueueExpectation3,
            deleteEvent2OnSerialQueueExpectation3,
            deleteEvent2OnConcurrentQueueExpectation3
        ], timeout: 10)
        
        // Now events e1_1, e2_1 and e3 should still be in
        
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        let storedEvent1_1 = storedEvents.first(where: { $0.localId == e1_1.localId })
        let storedEvent2_1 = storedEvents.first(where: { $0.localId == e2_1.localId })
        deletedEvent1_2 = storedEvents.first(where: { $0.localId == e1_2.localId })
        deletedEvent2_2 = storedEvents.first(where: { $0.localId == e2_2.localId })
        
        XCTAssert(
            storedEvent1_1?.localId != nil &&
            storedEvent1_1?.localId == e1_1.localId &&
            eventsIds.contains(storedEvent1_1!.localId),
            "Analytics file should contain event \(e1_1.localId)"
        )
        
        XCTAssert(
            storedEvent2_1?.localId != nil &&
            storedEvent2_1?.localId == e2_1.localId &&
            eventsIds.contains(storedEvent2_1!.localId),
            "Analytics file should contain event \(e2_1.localId)"
        )
        
        XCTAssert(deletedEvent1_2 == nil, "Event \(e1_2.localId) should be deleted")
        XCTAssert(deletedEvent2_2 == nil, "Event \(e2_2.localId) should be deleted")
    }
    
    func test_race_conditions_on_syncing() throws {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.mockSuccessfulResponses()
        Analytics.apiClient = mockApiClient
        
        self.cleanUpAnalytics()
        self.createAnalyticsFileForRC3()
        
        var storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        
        let events = self.createEvents(1000, withMessage: "A message")
        var eventsIds: [String] = []
        
        let serialQueue      = DispatchQueue(label: "Serial Queue")
        let concurrentQueue  = DispatchQueue(label: "Concurrent Queue", attributes: .concurrent)
        
        let writeEventsExpectation = expectation(description: "Write events")
        var expectationsToBeFulfilled: [XCTestExpectation] = [writeEventsExpectation]
        
        firstly {
            Analytics.Service.record(events: events)
        }
        .done {
            eventsIds.append(contentsOf: events.compactMap({ $0.localId }))
        }
        .ensure {
            writeEventsExpectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")
        
        let createClientSessionExpectation    = expectation(description: "Create client session")
        expectationsToBeFulfilled = [createClientSessionExpectation]
        
        firstly {
            self.createDemoClientSessionAndSetAppState()
        }
        .done { clientToken in
            
        }
        .ensure {
            createClientSessionExpectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 30)
        
        let syncOnMainQueueExpectation        = expectation(description: "Sync on main queue expectation")
        let syncOnSerialQueueExpectation1     = expectation(description: "Sync on serial queue expectation 1")
        let syncOnSerialQueueExpectation2     = expectation(description: "Sync on serial queue expectation 2")
        let syncOnConcurrentQueueExpectation1 = expectation(description: "Sync on concurrent queue expectation 1")
        let syncOnConcurrentQueueExpectation2 = expectation(description: "Sync on concurrent queue expectation 2")
        
        expectationsToBeFulfilled = [
            syncOnMainQueueExpectation,
            syncOnSerialQueueExpectation1,
            syncOnSerialQueueExpectation2,
            syncOnConcurrentQueueExpectation1,
            syncOnConcurrentQueueExpectation2
        ]
        
        
        self.syncAnalyticsFile(fromQueue: DispatchQueue.main) {
            syncOnMainQueueExpectation.fulfill()
        }
        
        self.syncAnalyticsFile(fromQueue: serialQueue) {
            syncOnSerialQueueExpectation1.fulfill()
        }
        
        self.syncAnalyticsFile(fromQueue: serialQueue) {
            syncOnSerialQueueExpectation2.fulfill()
        }
        
        self.syncAnalyticsFile(fromQueue: concurrentQueue) {
            syncOnConcurrentQueueExpectation1.fulfill()
        }
        
        self.syncAnalyticsFile(fromQueue: concurrentQueue) {
            syncOnConcurrentQueueExpectation2.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 60)
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        let nonNetworkEvents = storedEvents.filter({ $0.eventType != .networkCall && $0.eventType != .networkConnectivity })
        XCTAssert(nonNetworkEvents.count == 0, "nonNetworkEvents: \(nonNetworkEvents.count)")
    }
    
    func test_race_conditions_on_creating_events_and_deleting_analytics_file() throws {
        self.cleanUpAnalytics()
        self.createAnalyticsFileForRC3()
        
        self.createAnalyticsFileForRC3()
        
        var storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.isEmpty, "storedEvents should be empty since load should delete migration events")
        
        let serialQueue     = DispatchQueue(label: "Serial Queue")
        let concurrentQueue = DispatchQueue(label: "Concurrent Queue", attributes: .concurrent)
        
        var expectationsToBeFulfilled: [XCTestExpectation] = []
        
        let writeEventsOnMainQueueExpectation = expectation(description: "Write events from main queue")
        var writeEventsOnSerialQueueExpectation1 = expectation(description: "Write events on \(serialQueue.label) [1]")
        let writeEventsOnSerialQueueExpectation2 = expectation(description: "Write events on \(serialQueue.label) 2")
        var writeEventsOnConcurrentQueueExpectation1 = expectation(description: "Write events on \(concurrentQueue.label) 1")
        let writeEventsOnConcurrentQueueExpectation2 = expectation(description: "Write events on \(concurrentQueue.label) 2")
        expectationsToBeFulfilled = [
            writeEventsOnMainQueueExpectation,
            writeEventsOnSerialQueueExpectation1,
            writeEventsOnSerialQueueExpectation2,
            writeEventsOnConcurrentQueueExpectation1,
            writeEventsOnConcurrentQueueExpectation2
        ]
        
        // Record events from different queues
        
        var eventsIds: [String] = []
        
        var serialQueueEvents1 = self.createEvents(2, withMessage: "Serial queue 1")
        let serialQueueEvents2 = self.createEvents(2, withMessage: "Serial queue 2")
        var concurrentQueueEvents1 = self.createEvents(2, withMessage: "Concurrent queue 1")
        let concurrentQueueEvents2 = self.createEvents(2, withMessage: "Concurrent queue 2")
        var mainQueueEvents = self.createEvents(2, withMessage: "Main queue")
        
        self.writeEvents(serialQueueEvents1, fromQueue: serialQueue) {
            eventsIds.append(contentsOf: serialQueueEvents1.compactMap({ $0.localId }))
            writeEventsOnSerialQueueExpectation1.fulfill()
        }
        
        self.writeEvents(serialQueueEvents2, fromQueue: serialQueue) {
            eventsIds.append(contentsOf: serialQueueEvents2.compactMap({ $0.localId }))
            writeEventsOnSerialQueueExpectation2.fulfill()
        }
        
        self.writeEvents(concurrentQueueEvents1, fromQueue: concurrentQueue) {
            eventsIds.append(contentsOf: concurrentQueueEvents1.compactMap({ $0.localId }))
            writeEventsOnConcurrentQueueExpectation1.fulfill()
        }
        
        self.writeEvents(concurrentQueueEvents2, fromQueue: concurrentQueue) {
            eventsIds.append(contentsOf: concurrentQueueEvents2.compactMap({ $0.localId }))
            writeEventsOnConcurrentQueueExpectation2.fulfill()
        }
        
        self.writeEvents(mainQueueEvents, fromQueue: DispatchQueue.main) {
            eventsIds.append(contentsOf: mainQueueEvents.compactMap({ $0.localId }))
            writeEventsOnMainQueueExpectation.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        expectationsToBeFulfilled = []
                
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")
        
        for event in storedEvents {
            XCTAssert(eventsIds.contains(event.localId), "Analytics file should contain event \(event.localId)")
        }
        
        // Delete analytics file from different queues
        
        let deleteFileOnMainQueueExpectation1 = expectation(description: "Delete analytics file on main queue 1")
        let deleteFileOnSerialQueueExpectation1 = expectation(description: "Delete analytics file on \(serialQueue.label) 1")
        var deleteFileOnSerialQueueExpectation2 = expectation(description: "Delete analytics file on \(serialQueue.label) 2")
        var deleteFileOnConcurrentQueueExpectation1 = expectation(description: "Delete analytics file on \(concurrentQueue.label) 1")
        var deleteFileOnConcurrentQueueExpectation2 = expectation(description: "Delete analytics file on \(concurrentQueue.label) 2")
        expectationsToBeFulfilled = [
            deleteFileOnMainQueueExpectation1,
            deleteFileOnSerialQueueExpectation1,
            deleteFileOnSerialQueueExpectation2,
            deleteFileOnConcurrentQueueExpectation1,
            deleteFileOnConcurrentQueueExpectation2
        ]
        
        self.deleteAnalyticsFile(fromQueue: serialQueue) {
            deleteFileOnSerialQueueExpectation1.fulfill()
        }
        
        self.deleteAnalyticsFile(fromQueue: serialQueue) {
            deleteFileOnSerialQueueExpectation2.fulfill()
        }
        
        self.deleteAnalyticsFile(fromQueue: serialQueue) {
            deleteFileOnConcurrentQueueExpectation1.fulfill()
        }
        
        self.deleteAnalyticsFile(fromQueue: serialQueue) {
            deleteFileOnConcurrentQueueExpectation2.fulfill()
        }
        
        self.deleteAnalyticsFile(fromQueue: serialQueue) {
            deleteFileOnMainQueueExpectation1.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        expectationsToBeFulfilled = []
        
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.isEmpty, "Stored events in analytics file should be 0")
     
        // Rewrite some events
        
        let rewriteEventsFromMainQueueExpectation = expectation(description: "Rewrite events from the main queue")
        expectationsToBeFulfilled = [rewriteEventsFromMainQueueExpectation]
        
        mainQueueEvents = self.createEvents(5, withMessage: "A message")
        
        self.writeEvents(mainQueueEvents, fromQueue: DispatchQueue.main) {
            eventsIds = mainQueueEvents.compactMap({ $0.localId })
            rewriteEventsFromMainQueueExpectation.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        expectationsToBeFulfilled = []
        
        // TEST
        // - Write events from serial queue
        // - Delete analytics file from serial queue
        
        writeEventsOnSerialQueueExpectation1 = expectation(description: "Write events on \(serialQueue.label) [1]")
        deleteFileOnSerialQueueExpectation2 = expectation(description: "Delete analytics file on \(serialQueue.label) [2]")
        expectationsToBeFulfilled = [writeEventsOnSerialQueueExpectation1, deleteFileOnSerialQueueExpectation2]
        
        serialQueueEvents1 = self.createEvents(2, withMessage: "Serial queue 1")
                
        self.writeEvents(serialQueueEvents1, fromQueue: serialQueue) {
            eventsIds.append(contentsOf: serialQueueEvents1.compactMap({ $0.localId }))
            writeEventsOnSerialQueueExpectation1.fulfill()
        }
        
        self.deleteAnalyticsFile(fromQueue: serialQueue) {
            eventsIds = []
            deleteFileOnSerialQueueExpectation2.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        expectationsToBeFulfilled = []
        
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")
        
        // TEST
        // - Write events from serial queue
        // - Delete analytics file from serial queue
        
        writeEventsOnConcurrentQueueExpectation1 = expectation(description: "Write events on \(concurrentQueue.label) [1]")
        deleteFileOnConcurrentQueueExpectation2 = expectation(description: "Delete analytics file on \(concurrentQueue.label) [2]")
        expectationsToBeFulfilled = [writeEventsOnConcurrentQueueExpectation1, deleteFileOnConcurrentQueueExpectation2]
        
        concurrentQueueEvents1 = self.createEvents(2, withMessage: "Concurrent queue 1")
                
        self.writeEvents(concurrentQueueEvents1, fromQueue: concurrentQueue) {
            eventsIds.append(contentsOf: concurrentQueueEvents1.compactMap({ $0.localId }))
            writeEventsOnConcurrentQueueExpectation1.fulfill()
        }
        
        self.deleteAnalyticsFile(fromQueue: concurrentQueue) {
            eventsIds = []
            deleteFileOnConcurrentQueueExpectation2.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        expectationsToBeFulfilled = []
        
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")
        
        // TEST
        // - Write events from serial queue
        // - Delete analytics file from concurrent queue
        
        writeEventsOnSerialQueueExpectation1 = expectation(description: "Write events on \(serialQueue.label) [1]")
        deleteFileOnConcurrentQueueExpectation1 = expectation(description: "Delete analytics file on \(concurrentQueue.label) [1]")
        expectationsToBeFulfilled = [writeEventsOnSerialQueueExpectation1, deleteFileOnConcurrentQueueExpectation1]
        
        serialQueueEvents1 = self.createEvents(2, withMessage: "Serial queue 1")
                
        self.writeEvents(serialQueueEvents1, fromQueue: serialQueue) {
            eventsIds.append(contentsOf: serialQueueEvents1.compactMap({ $0.localId }))
            writeEventsOnSerialQueueExpectation1.fulfill()
        }
        
        self.deleteAnalyticsFile(fromQueue: concurrentQueue) {
            eventsIds = []
            deleteFileOnConcurrentQueueExpectation1.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        expectationsToBeFulfilled = []
        
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")
        
        
        // TEST
        // - Write events from concurrent queue
        // - Delete analytics file from serial queue
        
        let deleteEventsOnSerialQueueExpectation1 = expectation(description: "Write events on \(serialQueue.label) [1]")
        let writeFileOnConcurrentQueueExpectation1 = expectation(description: "Delete analytics file on \(concurrentQueue.label) [1]")
        expectationsToBeFulfilled = [deleteEventsOnSerialQueueExpectation1, writeFileOnConcurrentQueueExpectation1]
        
        concurrentQueueEvents1 = self.createEvents(2, withMessage: "Concurrent queue 1")
            
        self.deleteAnalyticsFile(fromQueue: serialQueue) {
            eventsIds = []
            deleteEventsOnSerialQueueExpectation1.fulfill()
        }
        
        self.writeEvents(concurrentQueueEvents1, fromQueue: concurrentQueue) {
            eventsIds.append(contentsOf: concurrentQueueEvents1.compactMap({ $0.localId }))
            writeFileOnConcurrentQueueExpectation1.fulfill()
        }
        
        wait(for: expectationsToBeFulfilled, timeout: 20)
        expectationsToBeFulfilled = []
        
        storedEvents = (try? Analytics.Service.loadEventsSynchronously()) ?? []
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")
    }    
}


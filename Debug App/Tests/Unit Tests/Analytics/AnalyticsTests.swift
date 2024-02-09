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

    override func tearDown() {
        self.cleanUpAnalytics()
    }

    var newEvents: [Analytics.Event] {
        return [
            Analytics.Event.message(
                message: "An error message",
                messageType: .error,
                severity: .error
            ),
            Analytics.Event.message(
                message: "An debug message",
                messageType: .other,
                severity: .debug
            ),
            Analytics.Event.ui(
                action: .click,
                context: nil,
                extra: "Extra",
                objectType: .button,
                objectId: .done,
                objectClass: "PrimerButton",
                place: .cardForm
            ),
            Analytics.Event.ui(
                action: .dismiss,
                context: nil,
                extra: "Extra",
                objectType: .view,
                objectId: nil,
                objectClass: "PrimerViewController",
                place: .threeDSScreen
            ),
            Analytics.Event.networkCall(
                callType: .requestStart,
                id: "id-0",
                url: "https://url.com",
                method: .get,
                errorBody: nil,
                responseCode: nil
            ),
            Analytics.Event.networkCall(
                callType: .requestEnd,
                id: "id-0",
                url: "https://url.com",
                method: .get,
                errorBody: "An error body",
                responseCode: 500
            ),
            Analytics.Event.networkConnectivity(networkType: .wifi),
            Analytics.Event.sdk(
                name: "Class.Function",
                params: [
                    "key1": "val1",
                    "key2": "val2"
                ]
            )
        ]
    }

    func test_record_new_events() throws {
        self.createMockAnalyticsFile()

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
            return Promise.fulfilled(self.storage.loadEvents())
        }
        .done { events in
            storedEvents = events
            exp.fulfill()
        }
        .catch { _ in
            XCTFail()
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
            Promise.fulfilled(self.storage.loadEvents())
        }
        .done { events in
            storedEvents = events
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)

        guard let newEvents = newEvents, !newEvents.isEmpty else {
            XCTFail("Failed to created new events")
            return
        }

        guard let storedEvents = storedEvents else {
            XCTFail("Failed to load stored events")
            return
        }

        XCTAssert(storedEvents.isEmpty, "There shouldn't be any stored events. storedEvents.count = \(storedEvents)")
    }

    func test_corrupt_analytics_file_with_rc_3_events() throws {
        let createClientSessionExpectation = expectation(description: "Create client session")
        var expectationsToBeFulfilled = [createClientSessionExpectation]

        firstly {
            self.createDemoClientSessionAndSetAppState()
        }
        .done { _ in

        }
        .ensure {
            createClientSessionExpectation.fulfill()
        }
        .catch { err in
            XCTAssert(false, err.localizedDescription)
        }

        wait(for: expectationsToBeFulfilled, timeout: 30)

        self.cleanUpAnalytics()

        self.createMockAnalyticsFile()

        let writeEventExpectation = expectation(description: "Create client session")
        expectationsToBeFulfilled = [writeEventExpectation]

        let newEvents = self.createEvents(10, withMessage: "A message")

        Analytics.Service.record(events: newEvents)
            .ensure {
                writeEventExpectation.fulfill()
            }
            .catch { err in
                XCTAssert(false, err.localizedDescription)
            }

        wait(for: expectationsToBeFulfilled, timeout: 30)

        let storedEvents = storage.loadEvents()
        XCTAssert(storedEvents.count == 10, "storedEvents should be 10")
    }

    func test_sync() throws {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.sendAnalyticsEventsResult = (Analytics.Service.Response(id: "mock-d", result: "success"), nil)
        Analytics.apiClient = mockApiClient
        recreateService()

        self.createMockAnalyticsFile()

        let exp = expectation(description: "Await")

        var storedEvents: [Analytics.Event]?

        self.deleteAnalyticsFileSynchonously()

        firstly {
            // Create events without having a client token yet
            self.createEvents()
        }
        .then { events in
            Analytics.Service.record(events: events)
        }
        .then {
            Analytics.Service.flush()
        }
        .then {
            self.createEvents()
        }
        .then { events in
            Analytics.Service.record(events: events)
        }
        .then {
            Promise.fulfilled(self.storage.loadEvents())
        }
        .then { _ in
            Analytics.Service.flush()
        }
        .then {
            Promise.fulfilled(self.storage.loadEvents())
        }
        .done { events in
            storedEvents = events
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: 600)

        let nonNetworkEvents = storedEvents?.filter({ $0.eventType != .networkCall && $0.eventType != .networkConnectivity })
        XCTAssert((nonNetworkEvents ?? []).count == 0, "nonNetworkEvents: \(nonNetworkEvents?.count)")
    }

    func test_delete_analytics_file() throws {
        self.createMockAnalyticsFile()

        let exp = expectation(description: "Await")

        firstly {
            self.createAnalyticsEvents(deletePreviousEvents: true)
        }
        .done { _ in
            self.deleteAnalyticsFileSynchonously()
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)

        if FileManager.default.fileExists(atPath: storage.fileURL.path) {
            XCTFail("Failed to delete analytics file at '\(storage.fileURL.absoluteString)'")
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

        let events = storage.loadEvents()
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
        self.createMockAnalyticsFile()

        var storedEvents = storage.loadEvents()
        XCTAssert(storedEvents.count == 0, "Analytics events should be empty")

        let serialQueue     = DispatchQueue(label: "Serial Queue")
        let concurrentQueue = DispatchQueue(label: "Concurrent Queue", attributes: .concurrent)

        let writeEventsOnMainQueueExpectation1 = expectation(description: "Write events on main queue 1")
        let writeEventsOnSerialQueueExpectation1 = expectation(description: "Write events on \(serialQueue.label) 1")
        let writeEventsOnSerialQueueExpectation2 = expectation(description: "Write events on \(serialQueue.label) 2")
        let writeEventsOnConcurrentQueueExpectation1 = expectation(description: "Write events on \(concurrentQueue.label) 1")
        let writeEventsOnConcurrentQueueExpectation2 = expectation(description: "Write events on \(concurrentQueue.label) 2")

        // Setup app state

        let appStateExpectation = self.expectation(description: "App state setup")

        firstly {
            self.createDemoClientSessionAndSetAppState().erase()
        }.done {
            appStateExpectation.fulfill()
        }.catch {
            XCTFail("Failed to setup app state: \($0.localizedDescription)")
        }

        wait(for: [appStateExpectation], timeout: 5.0)

        // Record events from different queues

        var eventsIds: [String] = []

        serialQueue.async {
            let e1_1 = Analytics.Event.message(
                message: "An error message 1.1",
                messageType: .error,
                severity: .error
            )

            firstly {
                Analytics.Service.record(events: [e1_1])
            }
            .done {
                eventsIds.append(e1_1.localId)
            }
            .catch { err in
                XCTFail(err.localizedDescription)
            }
            .finally {
                writeEventsOnSerialQueueExpectation1.fulfill()
            }
        }

        serialQueue.async {
            let e1_2 = Analytics.Event.message(
                message: "An error message 1.2",
                messageType: .error,
                severity: .error
            )

            firstly {
                Analytics.Service.record(events: [e1_2])
            }
            .done {
                eventsIds.append(e1_2.localId)
            }
            .catch { err in
                XCTFail(err.localizedDescription)
            }
            .finally {
                writeEventsOnSerialQueueExpectation2.fulfill()
            }
        }

        concurrentQueue.async {
            let e2_1 = Analytics.Event.message(
                message: "An error message 2.1",
                messageType: .error,
                severity: .error
            )

            firstly {
                Analytics.Service.record(events: [e2_1])
            }
            .done {
                eventsIds.append(e2_1.localId)
            }
            .catch { err in
                XCTFail(err.localizedDescription)
            }
            .finally {
                writeEventsOnConcurrentQueueExpectation1.fulfill()
            }

        }

        concurrentQueue.async {
            let e2_2 = Analytics.Event.message(
                message: "An error message 2.2",
                messageType: .error,
                severity: .error
            )

            firstly {
                Analytics.Service.record(events: [e2_2])
            }
            .done {
                eventsIds.append(e2_2.localId)
            }
            .catch { err in
                XCTFail(err.localizedDescription)
            }
            .finally {
                writeEventsOnConcurrentQueueExpectation2.fulfill()
            }
        }

        let e3 = Analytics.Event.message(
            message: "An error message 3",
            messageType: .error,
            severity: .error
        )

        firstly {
            Analytics.Service.record(events: [e3])
        }
        .done {
            eventsIds.append(e3.localId)
        }
        .catch { err in
            XCTFail(err.localizedDescription)
        }
        .finally {
            writeEventsOnMainQueueExpectation1.fulfill()
        }

        wait(for: [
            writeEventsOnMainQueueExpectation1,
            writeEventsOnSerialQueueExpectation1,
            writeEventsOnSerialQueueExpectation2,
            writeEventsOnConcurrentQueueExpectation1,
            writeEventsOnConcurrentQueueExpectation2
        ], timeout: 20)

        storedEvents = storage.loadEvents()
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events but found \(storedEvents.count)")
    }

    func test_race_conditions_on_syncing() throws {
        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.mockSuccessfulResponses()
        Analytics.apiClient = mockApiClient
        recreateService()

        self.cleanUpAnalytics()
        self.createMockAnalyticsFile()

        var storedEvents = storage.loadEvents()

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
        storedEvents = storage.loadEvents()
        XCTAssert(storedEvents.count == eventsIds.count, "Analytics file should contain \(eventsIds.count) events")

        let createClientSessionExpectation    = expectation(description: "Create client session")
        expectationsToBeFulfilled = [createClientSessionExpectation]

        firstly {
            self.createDemoClientSessionAndSetAppState()
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
        storedEvents = storage.loadEvents()
        let nonNetworkEvents = storedEvents.filter({ $0.eventType != .networkCall && $0.eventType != .networkConnectivity })
        XCTAssert(nonNetworkEvents.count == 0, "nonNetworkEvents: \(nonNetworkEvents.count)")
    }
}

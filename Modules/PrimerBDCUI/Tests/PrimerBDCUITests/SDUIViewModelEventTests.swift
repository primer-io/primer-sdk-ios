//
//  SDUIViewModelEventTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver
import XCTest

@available(iOS 16.0, *)
@MainActor
final class SDUIViewModelEventTests: XCTestCase {
    private var received: [CodableValue] = []
    private var held: [CheckedContinuation<Void, Never>] = []

    func testAClickRepeatedBeforeTheFirstIsHandledIsDropped() async {
        let sut = makeSUT()

        sut.applyEvent(.click(id: "pay"))
        sut.applyEvent(.click(id: "pay"))
        await waitForEvents(1)
        await settle()

        XCTAssertEqual(received.count, 1)
    }

    func testAClickIsTakenAgainOnceTheFirstIsHandled() async {
        let sut = makeSUT()

        sut.applyEvent(.click(id: "pay"))
        await waitForEvents(1)
        release()
        await settle()
        sut.applyEvent(.click(id: "pay"))
        await waitForEvents(2)

        XCTAssertEqual(received.count, 2)
    }

    func testClicksOnDifferentComponentsAndRepeatedChangesAllPass() async {
        let sut = makeSUT()

        sut.applyEvent(.click(id: "pay"))
        sut.applyEvent(.click(id: "back"))
        sut.applyEvent(.input(id: "email", value: .string("a"), type: .onChange))
        sut.applyEvent(.input(id: "email", value: .string("ab"), type: .onChange))
        await waitForEvents(4)

        XCTAssertEqual(received.count, 4)
    }

    func testAProviderEventRepeatedBeforeTheFirstIsHandledIsDropped() async {
        let sut = makeSUT()

        sut.applyEvent(.provider(type: "klarnaAuthorized", id: "widget", data: [:]))
        sut.applyEvent(.provider(type: "klarnaAuthorized", id: "widget", data: [:]))
        await waitForEvents(1)
        await settle()

        XCTAssertEqual(received.count, 1)
    }

    private func makeSUT() -> SDUIViewModel {
        SDUIViewModel(registry: PrimerStepResolverRegistry(), onEvent: { [weak self] event in
            await self?.hold(event)
        })
    }

    private func hold(_ event: CodableValue) async {
        received.append(event)
        await withCheckedContinuation { held.append($0) }
    }

    private func release() {
        held.forEach { $0.resume() }
        held = []
    }

    private func waitForEvents(_ count: Int) async {
        while received.count < count { await Task.yield() }
    }

    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
    }

    override func tearDown() async throws {
        release()
        try await super.tearDown()
    }
}

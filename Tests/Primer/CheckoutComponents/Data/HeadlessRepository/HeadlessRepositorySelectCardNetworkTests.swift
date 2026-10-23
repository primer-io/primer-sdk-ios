//
//  HeadlessRepositorySelectCardNetworkTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class SelectCardNetworkTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func test_selectCardNetwork_sendsNoClientSessionActionItself() async {
        await repository.selectCardNetwork(.visa)
        for _ in 0 ..< 10 { await Task.yield() }

        XCTAssertTrue(mockClientSessionActions.selectPaymentMethodCalls.isEmpty)
    }
}

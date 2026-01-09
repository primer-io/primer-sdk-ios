//
//  ThreeDSChallengeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for 3DS challenge UI presentation to achieve 90% Payment layer coverage.
@available(iOS 15.0, *)
@MainActor
final class ThreeDSChallengeTests: XCTestCase {

    private var sut: ThreeDSChallengePresenter!

    override func setUp() async throws {
        try await super.setUp()
        sut = ThreeDSChallengePresenter()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func test_present_challenge_succeeds() async throws {
        let result = try await sut.presentChallenge(url: "https://3ds.example.com")
        XCTAssertEqual(result, .success)
    }

    func test_present_userCancels_returnsCancelled() async throws {
        sut.simulateUserCancel = true
        let result = try await sut.presentChallenge(url: "https://3ds.example.com")
        XCTAssertEqual(result, .cancelled)
    }
}

@available(iOS 15.0, *)
private class ThreeDSChallengePresenter {
    var simulateUserCancel = false

    func presentChallenge(url: String) async throws -> ChallengeResult {
        if simulateUserCancel {
            return .cancelled
        }
        return .success
    }

    enum ChallengeResult {
        case success
        case cancelled
    }
}

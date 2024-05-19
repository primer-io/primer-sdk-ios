//
//  UserAgentTests.swift
//  
//
//  Created by Jack Newcombe on 13/05/2024.
//

import XCTest
@testable import PrimerSDK

final class UserAgentTests: XCTestCase {

    func testUserAgent() throws {
        let regex = try NSRegularExpression(pattern: "^xctest/\\d+\\.\\d+ arm64 iOS/\\d+\\.\\d+ CFNetwork/1\\.0 Darwin/\\d+\\.\\d+\\.0$")
        let range = NSRange(location: 0, length: UserAgent.userAgentAsString.count)
        print("USER AGENT: \(UserAgent.userAgentAsString)")
        XCTAssertEqual(regex.numberOfMatches(in: UserAgent.userAgentAsString, range: range), 1)
    }

}

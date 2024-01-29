//
//  ThreeDSProtocolVersionTests.swift
//  Debug App Tests
//
//  Created by Evangelos Pittas on 16/5/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class ThreeDSProtocolVersionTests: XCTestCase {
    
    func test_3DS_protocol_veresion_init() throws {
        var threeDSProtocolVersionStr = "1.0"
        var threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "1.9"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "1.9.999"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2.0"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2.0.999"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2.1"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_1_0)
        
        threeDSProtocolVersionStr = "2.1.0"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_1_0)
        
        threeDSProtocolVersionStr = "2.1.1"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_1_0)
        
        threeDSProtocolVersionStr = "2.1.999"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_1_0)
        
        threeDSProtocolVersionStr = "2.2"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_2_0)
        
        threeDSProtocolVersionStr = "2.2.0"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_2_0)
        
        threeDSProtocolVersionStr = "2.2.1"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_2_0)
        
        threeDSProtocolVersionStr = "2.2.999"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == .v_2_2_0)
        
        threeDSProtocolVersionStr = "2.3"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2.3.0"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2.3.1"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2.3.999"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "2.4"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "3"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "3.0"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "3.0.0"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "3.9"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
        
        threeDSProtocolVersionStr = "3.9.999"
        threeDSProtocolVersion = ThreeDS.ProtocolVersion(rawValue: threeDSProtocolVersionStr)
        XCTAssert(threeDSProtocolVersion == nil)
    }
}

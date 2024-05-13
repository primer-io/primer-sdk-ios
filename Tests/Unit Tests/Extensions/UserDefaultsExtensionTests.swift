//
//  UserDefaultsExtensionTests.swift
//  
//
//  Created by Jack Newcombe on 10/05/2024.
//

import XCTest
@testable import PrimerSDK

final class UserDefaultsExtensionTests: XCTestCase {

    override func tearDown() {
        UserDefaults.primerFramework.clearPrimerFramework()
    }

    func testUserDefaults_iOS() {
        UserDefaults.primerFramework.set("test", forKey: "test")
        XCTAssertEqual(UserDefaults(suiteName: Bundle.primerFrameworkIdentifier)!.string(forKey: "test"), "test")
    }
 
    func testUserDefaults_RN() {
        Primer.shared.integrationOptions = PrimerIntegrationOptions(reactNativeVersion: "123")
        UserDefaults.primerFramework.set("test", forKey: "test")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "test"), "test")
    }
}

//
//  PrimerCoreKit.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 11/5/21.
//

import Foundation

// swiftlint:disable identifier_name
private let _PrimerCoreKit = PrimerCoreKit()
// swiftlint:enable identifier_name

public class PrimerCoreKit {

    // MARK: - INITIALIZATION

    public static var shared: PrimerCoreKit {
        return _PrimerCoreKit
    }

    fileprivate init() {
        print("\n\nPrimerCoreKit initialized\nPrimerCoreKit includes Business logic, Network logic & useful helpers that might be used by any of the other components.")
    }
    
    public func testFunctionCall() {
        print("Function was called")
    }

}

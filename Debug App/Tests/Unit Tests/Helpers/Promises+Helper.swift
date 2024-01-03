//
//  Promises+Helper.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 01/12/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
@testable import PrimerSDK

extension Promise {
    static func fulfilled(_ value: T) -> Promise<T> {
        return Promise<T> { $0.fulfill(value) }
    }
    
    static func rejected(_ error: Error) -> Promise<T> {
        return Promise<T> { $0.reject(error) }
    }
    
    func erase() -> Promise<Void> {
        then { _ in
            Promise<Void>.fulfilled(())
        }
    }
}

//
//  Promises+Helper.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

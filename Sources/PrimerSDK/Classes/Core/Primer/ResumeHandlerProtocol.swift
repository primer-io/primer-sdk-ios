//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import Foundation

@objc
public protocol ResumeHandlerProtocol {
    func handle(error: Error)
    func handle(newClientToken clientToken: String)
    func handleSuccess()
}

#endif

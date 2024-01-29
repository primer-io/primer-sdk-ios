//
//  URL+NetworkHeaders.swift
//  Debug App
//
//  Created by Alexandra Lovin on 09.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
extension URL {
    static func requestSessionHTTPHeaders(useNewWorkflows: Bool) -> [String: String]? {
        useNewWorkflows ? ["Legacy-Workflows": "false"] : nil
    }
}

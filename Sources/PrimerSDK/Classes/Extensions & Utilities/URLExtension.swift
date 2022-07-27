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

internal extension URL {

    func parseURLQueryParameters() -> [String: String?]? {
        guard let urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems else { return nil }
        
        var result: [String: String?] = [:]

        for item in queryItems {
            result[item.name] = item.value
        }

        return result.keys.isEmpty ? nil : result
    }

    func queryParameterValue(for param: String) -> String? {
        guard let urlQueryParameters = parseURLQueryParameters(),
              let value = urlQueryParameters[param] else { return nil }
        return value
    }

}

#endif

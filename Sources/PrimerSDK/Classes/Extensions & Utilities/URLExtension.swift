//
//  URLExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

import Foundation

internal extension URL {

    var queryParameters: [String: String]? {
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            let dic = queryItems.reduce(into: [String: String]()) { (result, item) in
                result[item.name] = item.value
            }
            return dic
        }
        
        return nil
    }

    func queryParameterValue(for param: String) -> String? {
        guard let urlQueryParameters = queryParameters,
              let value = urlQueryParameters[param] else { return nil }
        return value
    }

}

//
//  URLExtension.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 18/3/21.
//

import Foundation

internal extension URL {
    
    var urlParameters: [String: Any] {
        var dict = [String: Any]()
        
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false) {
            if let queryItems = components.queryItems {
                for item in queryItems {
                    dict[item.name] = item.value!
                }
            }
            return dict
        } else {
            return [:]
        }
    }
    
}

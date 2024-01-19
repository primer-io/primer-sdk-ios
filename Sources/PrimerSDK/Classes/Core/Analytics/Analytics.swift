//
//  Analytics.swift
//  PrimerSDK
//
//  Created by Evangelos on 13/12/21.
//

import Foundation

class Analytics {
    static let queue: DispatchQueue = DispatchQueue(label: "primer.analytics", qos: .utility)
    static var apiClient: PrimerAPIClientProtocol?
}

//
//  Notification.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/9/22.
//

import Foundation

extension Notification.Name {

    static let receivedUrlSchemeRedirect        = Notification.Name(rawValue: "PrimerURLSchemeRedirect")
    static let receivedUrlSchemeCancellation    = Notification.Name(rawValue: "PrimerURLSchemeCancellation")
}

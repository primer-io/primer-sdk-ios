//
//  ResumeHandlerProtocol.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 15/9/21.
//

import Foundation

@objc
public protocol ResumeHandlerProtocol {
    func resume(withError error: Error)
    func resume(withClientToken clientToken: String?)
}

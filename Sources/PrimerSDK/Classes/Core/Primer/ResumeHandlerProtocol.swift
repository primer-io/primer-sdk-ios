//
//  ResumeHandlerProtocol.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 15/9/21.
//



import Foundation

@objc
public protocol ResumeHandlerProtocol {
    func handle(error: Error)
    func handle(newClientToken clientToken: String)
    func handleSuccess()
}



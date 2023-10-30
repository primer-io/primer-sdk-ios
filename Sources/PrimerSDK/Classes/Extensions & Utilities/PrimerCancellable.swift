//
//  Cancellable.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

protocol PrimerCancellable {
    /// Cancel the associated task
    func cancel()
}

extension URLSessionDataTask: PrimerCancellable {}

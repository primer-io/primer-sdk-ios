//
//  WebStep.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 21.11.2023.
//

import Foundation
enum WebStep: PrimerHeadlessStep {
    case loading
    case loaded
    case dismissed
    case success
    case failure
}

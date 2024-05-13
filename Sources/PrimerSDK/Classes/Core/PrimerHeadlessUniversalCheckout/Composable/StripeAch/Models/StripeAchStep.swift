//
//  ACHStep.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation
import UIKit
/**
 * This enum is used to communicate the result of attempting to collect the user details from server, if there are any.
 * and communicate that tokenization proccess started.
 * It conforms to `PrimerHeadlessStep`.
 *
 * Cases:
 * - `didFetchUserDetails`: Collection of the user details. It caries:
 *     - `details` of type `ACHUserDetails`, representing the object that wrapps the user details (firstName lastName and emailAddress).
 *
 * - `tokenizationStarted`: Indicates that the ACH tokenization has started.
 * - `notInitialized`: Indicates that the ACH logic is not initialized.
 */
public enum ACHStep: PrimerHeadlessStep {
    /// Session creation
    case didFetchUserDetails(_ details: ACHUserDetails)
    case tokenizationStarted
    case notInitialized
}

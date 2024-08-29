//
//  ACHUserDetailsStep.swift
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
 * - `retrievedUserDetails`: Collection of the user details. It caries:
 *     - `details` of type `ACHUserDetails`, representing the object that wrapps the user details (firstName lastName and emailAddress).
 *
 * - `didCollectUserDetails`: Indicates that user details were collected and tokenization started.
 * - `notInitialized`: Indicates that the ACH logic is not initialized.
 */
public enum ACHUserDetailsStep: PrimerHeadlessStep {
    /// Session creation
    case retrievedUserDetails(_ details: ACHUserDetails)
    case didCollectUserDetails
    case notInitialized
}

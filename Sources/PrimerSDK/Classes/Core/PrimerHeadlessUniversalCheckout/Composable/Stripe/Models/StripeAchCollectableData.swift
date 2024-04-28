//
//  StripeAchCollectableData.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Enumerates the types of data that can be collected during a Stripe ACH payment session.
 * It conforms to `PrimerCollectableData` for integration with the Primer SDK data collection process and is `Encodable` to facilitate serialization.
 *
 * Cases:
 *  - `collectUserDetails(_ details: StripeAchUserDetails)`: Represents the collection of the user details, wrapped into `StripeAchUserDetails` object.
 */
public enum StripeAchCollectableData: PrimerCollectableData, Encodable {
    case collectUserDetails(_ details: StripeAchUserDetails)
}

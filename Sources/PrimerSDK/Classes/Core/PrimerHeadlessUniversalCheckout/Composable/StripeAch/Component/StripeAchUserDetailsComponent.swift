//
//  StripeAchUserDetailsComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

public protocol StripeAchUserDetailsComponent: PrimerHeadlessMainComponent where Data == StripeAchCollectableData, Step == StripeAchStep {}

//
//  StripeAchUserDetailsComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

public protocol PrimerHeadlessAchComponent: PrimerHeadlessCollectDataComponent {}

public protocol StripeAchUserDetailsComponent: PrimerHeadlessAchComponent where Data == ACHUserDetailsCollectableData, Step == ACHUserDetailsStep {}

//
//  StripeAchUserDetailsComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public protocol PrimerHeadlessAchComponent: PrimerHeadlessCollectDataComponent {}

public protocol StripeAchUserDetailsComponent: PrimerHeadlessAchComponent where Data == ACHUserDetailsCollectableData, Step == ACHUserDetailsStep {}

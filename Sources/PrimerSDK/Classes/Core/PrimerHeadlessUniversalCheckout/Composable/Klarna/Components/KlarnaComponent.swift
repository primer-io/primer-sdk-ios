//
//  PrimerHeadlessKlarnaComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 29.01.2024.
//

import Foundation

public protocol KlarnaComponent: PrimerHeadlessMainComponent where Data == KlarnaCollectableData, Step == KlarnaStep {}

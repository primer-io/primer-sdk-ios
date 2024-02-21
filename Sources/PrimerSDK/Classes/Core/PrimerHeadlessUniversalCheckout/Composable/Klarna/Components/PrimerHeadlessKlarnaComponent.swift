//
//  PrimerHeadlessKlarnaComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 29.01.2024.
//

import Foundation

public protocol PrimerHeadlessKlarnaDelegates: PrimerHeadlessValidatableDelegate, PrimerHeadlessErrorableDelegate, PrimerHeadlessSteppableDelegate {}
public protocol PrimerHeadlessKlarnaComponent: PrimerHeadlessMainComponent where Data == KlarnaCollectableData, Step == KlarnaStep {}

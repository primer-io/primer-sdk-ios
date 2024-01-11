//
//  BanksComponent.swift
//  PrimerSDK
//
//  Created by Alexandra Lovin on 21.11.2023.
//

import Foundation

public protocol BanksComponent: PrimerHeadlessMainComponent where Data == BanksCollectableData, Step == BanksStep { }

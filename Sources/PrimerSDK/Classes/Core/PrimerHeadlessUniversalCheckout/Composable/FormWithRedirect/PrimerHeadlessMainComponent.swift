//
//  File.swift
//  
//
//  Created by Alexandra Lovin on 14.11.2023.
//

import Foundation
protocol MainCollectableData: PrimerCollectableData {}

public protocol PrimerHeadlessMainComponent: PrimerHeadlessCollectDataComponent, PrimerHeadlessCancellable {}

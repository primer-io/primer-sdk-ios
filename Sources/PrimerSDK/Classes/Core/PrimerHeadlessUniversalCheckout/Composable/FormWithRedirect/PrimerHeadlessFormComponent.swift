//
//  File.swift
//  
//
//  Created by Alexandra Lovin on 14.11.2023.
//

import Foundation
protocol FormCollectableData: PrimerCollectableData {}

public protocol PrimerHeadlessFormComponent: PrimerHeadlessCollectDataComponent, PrimerHeadlessCancellable {}

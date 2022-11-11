//
//  PMF.swift
//  PrimerSDK
//
//  Created by Evangelos on 1/11/22.
//

#if canImport(UIKit)

import UIKit

internal class PMF: Codable {
    
    var events: [PMF.Event]
    var screens: [PMF.Screen]
    var headless: PMF.Headless
}

#endif

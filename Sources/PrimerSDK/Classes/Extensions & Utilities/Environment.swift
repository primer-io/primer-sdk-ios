//
//  Environment.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 26/10/2023.
//

import Foundation

final class RuntimeEnvironment {
    
    static func contains(variableNamed name: String) -> Bool {
        ProcessInfo.processInfo.environment.keys.contains(name)
    }
}

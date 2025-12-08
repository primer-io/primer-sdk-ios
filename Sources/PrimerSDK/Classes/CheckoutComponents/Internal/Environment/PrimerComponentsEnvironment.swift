//
//  PrimerComponentsEnvironment.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Environment Key for PrimerComponents

@available(iOS 15.0, *)
private struct PrimerComponentsKey: EnvironmentKey {
    static let defaultValue: PrimerComponents = PrimerComponents()
}

@available(iOS 15.0, *)
extension EnvironmentValues {
    var primerComponents: PrimerComponents {
        get { self[PrimerComponentsKey.self] }
        set { self[PrimerComponentsKey.self] = newValue }
    }
}

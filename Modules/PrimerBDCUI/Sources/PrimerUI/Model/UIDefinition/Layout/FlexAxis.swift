//
//  FlexAxis.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

enum FlexAxis {
    case row
    case column
}

extension EnvironmentValues {
    var flexAxis: FlexAxis {
        get { self[FlexAxisKey.self] }
        set { self[FlexAxisKey.self] = newValue }
    }
}

extension EnvironmentValues {
    var flexCrossAxisStretch: Bool {
        get { self[FlexCrossAxisStretchKey.self] }
        set { self[FlexCrossAxisStretchKey.self] = newValue }
    }
}

private struct FlexAxisKey: EnvironmentKey {
    static let defaultValue: FlexAxis = .row
}

private struct FlexCrossAxisStretchKey: EnvironmentKey {
    static let defaultValue = false
}

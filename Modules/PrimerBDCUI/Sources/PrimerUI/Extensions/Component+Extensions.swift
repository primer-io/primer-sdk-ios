//
//  Component+Extensions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

extension Component {
    var selectable: Selectable? {
        switch self {
        case let .list(_, props): props
        case let .selectionGroup(props): props
        default: nil
        }
    }
}

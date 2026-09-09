//
//  Selectable.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

protocol Selectable: UI {
    var values: Set<String> { get }
    var mode: SelectionMode { get }
}

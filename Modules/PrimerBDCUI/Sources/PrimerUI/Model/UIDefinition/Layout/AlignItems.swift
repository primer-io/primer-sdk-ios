//
//  AlignItems.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

enum AlignItems: String, UI, SingleValueContained {
    case stretch
    case center
    case flexStart = "flex-start"
}

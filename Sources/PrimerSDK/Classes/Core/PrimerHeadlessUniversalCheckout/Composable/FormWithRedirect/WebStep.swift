//
//  WebStep.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
enum WebStep: PrimerHeadlessStep {
    case loading
    case loaded
    case dismissed
    case success
    case failure
}

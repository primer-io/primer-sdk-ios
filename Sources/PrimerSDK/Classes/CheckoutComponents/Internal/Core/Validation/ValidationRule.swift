//
//  ValidationRule.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

protocol ValidationRule {
  associatedtype Input
  func validate(_ input: Input) -> ValidationResult
}

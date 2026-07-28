//
//  PrimerUI.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

public nonisolated(unsafe) var resolveColor: ((String) -> Color)! = { _ in fatalError("Must override resolveColor") }
public nonisolated(unsafe) var resolveSpacing: ((String) -> CGFloat)! = { _ in fatalError("Must override resolveSpacing") }
public nonisolated(unsafe) var resolveFont: ((String) -> Font)! = { _ in fatalError("Must override resolveFont") }

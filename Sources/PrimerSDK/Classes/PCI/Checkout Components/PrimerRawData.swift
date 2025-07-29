//
//  PrimerRawData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

internal protocol PrimerRawDataProtocol {
    var onDataDidChange: (() -> Void)? { get set }
}

public class PrimerRawData: NSObject, PrimerRawDataProtocol {

    var onDataDidChange: (() -> Void)?
}

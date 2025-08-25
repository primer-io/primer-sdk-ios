//
//  PrimerRetailerData.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public final class PrimerRetailerData: PrimerRawData {

    public var id: String {
        didSet {
            self.onDataDidChange?()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id = "retailOutlet"
    }

    public required init(id: String) {
        self.id = id
        super.init()
    }
}

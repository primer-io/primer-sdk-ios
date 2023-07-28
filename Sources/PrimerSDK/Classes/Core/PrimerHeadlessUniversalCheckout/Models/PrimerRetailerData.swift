//
//  PrimerRawRetailerData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 15/10/22.
//

#if canImport(UIKit)

import Foundation

public class PrimerRetailerData: PrimerRawData {
    
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
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
    }
}

#endif

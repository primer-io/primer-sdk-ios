//
//  PrimerRawRetailerData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 15/10/22.
//

import Foundation

public final class PrimerRetailerData: PrimerRawData {

    public var id: String {
        didSet {
            onDataDidChange?()
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

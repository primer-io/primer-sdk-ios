//
//  PrimerRawRetailerData.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 15/10/22.
//

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
}

//
//  PrimerKlarnaPaymentCategory.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 06.11.2023.
//

import Foundation

public struct PrimerKlarnaPaymentCategory {
    public let id: String
    public let name: String
    public let descriptiveAssetUrl: String
    public let standardAssetUrl: String
    
    // MARK: - Init
    init(response: Response.Body.Klarna.SessionCategory) {
        self.id = response.identifier
        self.name = response.name
        self.descriptiveAssetUrl = response.descriptiveAssetUrl
        self.standardAssetUrl = response.standardAssetUrl
    }
}

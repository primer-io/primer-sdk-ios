//
//  KlarnaPaymentCategory.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.01.2024.
//

import Foundation

public struct KlarnaPaymentCategory {
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

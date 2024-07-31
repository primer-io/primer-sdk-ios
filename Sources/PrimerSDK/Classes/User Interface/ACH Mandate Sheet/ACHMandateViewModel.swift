//
//  ACHMandateViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI

class ACHMandateViewModel: ObservableObject {

    private var mandateData: PrimerStripeOptions.MandateData

    @Published var shouldDisableViews: Bool = false

    init(mandateData: PrimerStripeOptions.MandateData) {
        self.mandateData = mandateData
    }

    var mandateText: String {
        switch mandateData {
        case .fullMandate(let text):
            return text
        case .templateMandate(let merchantName):
            return Strings.Mandate.getTemplateText(merchantName: merchantName)
        }
    }
}

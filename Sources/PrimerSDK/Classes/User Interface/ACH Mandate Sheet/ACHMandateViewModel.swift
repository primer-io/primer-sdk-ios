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
            let arguments = getArgumentsList(argument: merchantName, template: Strings.Mandate.templateText)
            return String(format: Strings.Mandate.templateText, arguments: arguments)
        }
    }

    private func getArgumentsList(argument: String, template: String) -> [String] {
        var arguments: [String] = []

        let placeholderCount = template.components(separatedBy: "%@").count - 1
        arguments = Array(repeating: argument, count: placeholderCount)

        return arguments
    }
}

//
//  ACHMandateViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI

class ACHMandateViewModel: ObservableObject {
    func getMandateText(for mandateData: PrimerStripeOptions.MandateData) -> String {
        switch mandateData {
        case .fullMandate(text: let text):
            return text
        case .templateMandate(merchantName: let merchantName):
            return """
                    By clicking [accept], you authorise [\(merchantName)] to debit the bank account specified above for any amount owed for charges arising from your use of [\(merchantName)]'s services and/or purchase of products from [\(merchantName)], pursuant to [\(merchantName)]'s website and terms, until this authorisation is revoked. You may amend or cancel this authorisation at any time by providing notice to [\(merchantName)] with 30 (thirty) days notice.
                    
                    If you use [\(merchantName)]'s services or purchase additional products periodically pursuant to [\(merchantName)]'s terms, you authorise [\(merchantName)] to debit your bank account periodically. Payments that fall outside the regular debits authorised above will only be debited after your authorisation is obtained.
                    """
        }
    }
}

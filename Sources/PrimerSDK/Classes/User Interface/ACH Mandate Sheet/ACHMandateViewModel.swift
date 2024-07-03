//
//  ACHMandateViewModel.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 03.07.2024.
//

import SwiftUI

class ACHMandateViewModel: ObservableObject {
    func getMandateText(for businessName: String) -> String {
        return """
                By clicking [accept], you authorise [\(businessName)] to debit the bank account specified above for any amount owed for charges arising from your use of [\(businessName)]'s services and/or purchase of products from [\(businessName)], pursuant to [\(businessName)]'s website and terms, until this authorisation is revoked. You may amend or cancel this authorisation at any time by providing notice to [\(businessName)] with 30 (thirty) days notice.
                
                If you use [\(businessName)]'s services or purchase additional products periodically pursuant to [\(businessName)]'s terms, you authorise [\(businessName)] to debit your bank account periodically. Payments that fall outside the regular debits authorised above will only be debited after your authorisation is obtained.
                """
    }
}

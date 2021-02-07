//
//  ConfirmMandateViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK


class MockConfirmMandateViewModel: ConfirmMandateViewModelProtocol {
    var formCompleted: Bool = false
    
    var mandate: DirectDebitMandate {
        return DirectDebitMandate(firstName: "", lastName: "", email: "", iban: "", accountNumber: "", sortCode: "", address: nil)
    }
    
    var businessDetails: BusinessDetails?
    
    var amount: String {
        return ""
    }
    
    func loadConfig(_ completion: @escaping (Error?) -> Void) {
        
    }
    
    func confirmMandateAndTokenize(_ completion: @escaping (Error?) -> Void) {
        
    }
    
    func eraseData() {
        
    }
    
     
}

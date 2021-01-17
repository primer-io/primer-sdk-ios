//
//  IBANFormViewModel.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 16/01/2021.
//

@testable import PrimerSDK

class MockIBANFormViewModel: IBANFormViewModelProtocol {
    
    var confirmMandateViewModel: ConfirmMandateViewModelProtocol {
        return ConfirmMandateViewModel()
    }
    
    var theme: PrimerTheme {
        return PrimerTheme()
    }
}

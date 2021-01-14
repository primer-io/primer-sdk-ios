//
//  IBANFormViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

protocol IBANFormViewModelProtocol {
    var confirmMandateViewModel: ConfirmMandateViewModelProtocol { get }
    var theme: PrimerTheme { get }
}

class IBANFormViewModel: IBANFormViewModelProtocol {
    
    var theme: PrimerTheme { return settings.theme }
    
    let confirmMandateViewModel: ConfirmMandateViewModelProtocol
    let settings: PrimerSettings
    
    init(
        with confirmMandateViewModel: ConfirmMandateViewModelProtocol,
        and settings: PrimerSettings
    ) {
        self.confirmMandateViewModel = confirmMandateViewModel
        self.settings = settings
    }
    
}

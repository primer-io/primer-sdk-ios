//
//  IBANFormViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 10/01/2021.
//

protocol IBANFormViewModelProtocol {
    var theme: PrimerTheme { get }
}

class IBANFormViewModel: IBANFormViewModelProtocol {
    
    var theme: PrimerTheme { return context.state.settings.theme }
    let context: CheckoutContextProtocol
    
    init(context: CheckoutContextProtocol) {
        self.context = context
    }
    
}

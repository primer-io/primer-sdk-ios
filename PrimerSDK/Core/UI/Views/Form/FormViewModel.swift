//
//  FormViewModel.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 14/02/2021.
//
protocol FormViewModelProtocol {
    var popOnComplete: Bool { get }
    var mandate: DirectDebitMandate { get }
    func getSubmitButtonTitle(formType: FormType) -> String
    func setState(_ value: String?, type: FormTextFieldType)
    func onSubmit(formType: FormType) -> Void
    func onBottomLinkTapped(delegate: CardScannerViewControllerDelegate) -> Void
    func submit(completion: @escaping (PrimerError?) -> Void)
    func onReturnButtonTapped() -> Void
}

class FormViewModel: FormViewModelProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var tokenizationService: TokenizationServiceProtocol
    @Dependency private(set) var router: RouterDelegate
    @Dependency private(set) var theme: PrimerTheme

    var popOnComplete: Bool {
        return state.directDebitFormCompleted
    }
    
    var mandate: DirectDebitMandate {
        return state.directDebitMandate
    }
    
    func getSubmitButtonTitle(formType: FormType) -> String {
        switch formType {
        case .cardForm: return "Add card".localized()
        default: return "Next".localized()
        }
    }
    
    func setState(_ value: String?, type: FormTextFieldType) {
        switch type {
        case .iban: state.directDebitMandate.iban = value?.withoutWhiteSpace
        case .accountNumber: state.directDebitMandate.accountNumber = value
        case .addressLine1: state.directDebitMandate.address?.addressLine1 = value
        case .addressLine2: state.directDebitMandate.address?.addressLine2 = value
        case .city: state.directDebitMandate.address?.city = value
        case .country: state.directDebitMandate.address?.countryCode = value
        case .email: state.directDebitMandate.email = value
        case .firstName: state.directDebitMandate.firstName = value
        case .lastName: state.directDebitMandate.lastName = value
        case .postalCode: state.directDebitMandate.address?.postalCode = value
        case .sortCode: state.directDebitMandate.sortCode = value
        case .cardholderName: state.cardData.name = value ?? ""
        case .cardNumber: state.cardData.number = value?.withoutWhiteSpace ?? ""
        case .expiryDate:
            guard let expiryValues = value?.split(separator: "/") else { return }
            let expMonth = "\(expiryValues[0])"
            let expYear = "20\(expiryValues[1])"
            state.cardData.expiryYear = expYear
            state.cardData.expiryMonth = expMonth
        case .cvc: state.cardData.cvc = value ?? ""
        }
    }
    
    func onSubmit(formType: FormType) {
        if (popOnComplete) { return router.pop() }
        
        switch formType {
        case .iban:
            router.show(.form(type: .name(mandate: mandate)))
        case .bankAccount:
            router.show(.form(type: .name(mandate: mandate)))
        case .name:
            router.show(.form(type: .email(mandate: mandate)))
        case .email:
            router.show(.form(type: .address(mandate: mandate)))
        case .address:
            router.popAllAndShow(.confirmMandate)
        case .cardForm: submit() { error in
            DispatchQueue.main.async { [weak self] in
                if (error.exists) {
                    self?.router.show(.error(message: error!.rawValue))
                } else {
                    self?.router.show(.success(type: .regular))
                }
            }
        }
        }
    }
    
    func onBottomLinkTapped(delegate: CardScannerViewControllerDelegate) {
        router.show(.cardScanner(delegate: delegate))
    }
    
    func onReturnButtonTapped() {
        router.pop()
    }
    
    func submit(completion: @escaping (PrimerError?) -> Void) {
        let instrument = PaymentInstrument(
            number: state.cardData.number,
            cvv: state.cardData.cvc,
            expirationMonth: state.cardData.expiryMonth,
            expirationYear: state.cardData.expiryYear,
            cardholderName: state.cardData.name
        )
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
        self.tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error): completion(error)
            case .success(let token):
                switch Primer.flow {
                case .completeDirectCheckout:
                    self?.state.settings.onTokenizeSuccess(token, { error in
                        if (error.exists) {
                            completion(PrimerError.TokenizationRequestFailed)
                        } else {
                            completion(nil)
                        }
                    })
                default:
                    completion(nil)
                }
            }
        }
    }
}

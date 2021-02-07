//
//  BankAccountFormViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//

import UIKit

class FormViewController: UIViewController {
    let subview: FormView = FormView()
    
    @Dependency private(set) var viewModel: FormViewModelProtocol
    @Dependency private(set) var router: RouterDelegate
    weak var reloadDelegate: ReloadDelegate?
    
    var formType: FormType
    
    init(formType: FormType) {
        self.formType = formType
        super.init(nibName: nil, bundle: nil)
        view.addSubview(subview)
        subview.delegate = self
        subview.pin(to: view)
        subview.render()
        view.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    deinit { print("🧨 destroy:", self.self) }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.isHidden = true
    }
}

extension FormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
      textField.resignFirstResponder()
      return true
    }
}

extension FormViewController: FormViewDelegate {
    
    func back() {
        router.pop()
    }
    
    func openLink() {
        switch formType {
//        case .iban: router?.popAndShow(.form(type: .bankAccount(mandate: viewModel.mandate)))
//        case .bankAccount: router?.popAndShow(.form(type: .iban(mandate: viewModel.mandate)))
        default: break
        }
    }
    
    func submit(_ value: String?, type: FormTextFieldType) {
        viewModel.setState(value, type: type)
    }
    
    var submitButtonTitle: String {
        return viewModel.getSubmitButtonTitle(formType: formType)
    }
    
    func onSubmit() {
        switch formType {
        case .iban:
            if (viewModel.popOnComplete) { return router.pop() }
            router.show(.form(type: .name(mandate: viewModel.mandate)))
        case .bankAccount:
            if (viewModel.popOnComplete) { return router.pop() }
            router.show(.form(type: .name(mandate: viewModel.mandate)))
        case .name:
            if (viewModel.popOnComplete) { return router.pop() }
            router.show(.form(type: .email(mandate: viewModel.mandate)))
        case .email:
            if (viewModel.popOnComplete) { return router.pop() }
            router.show(.form(type: .address(mandate: viewModel.mandate)))
        case .address:
            if (viewModel.popOnComplete) { return router.pop() }
            router.popAllAndShow(.confirmMandate)
        case .cardForm: viewModel.submit() { error in
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
    
    func onBottomLinkTapped() { router.show(.cardScanner(delegate: self)) }
}

protocol FormViewModelProtocol {
    var popOnComplete: Bool { get }
    var mandate: DirectDebitMandate { get }
    func getSubmitButtonTitle(formType: FormType) -> String
    func setState(_ value: String?, type: FormTextFieldType)
    func submit(completion: @escaping (PrimerError?) -> Void)
}

class FormViewModel: FormViewModelProtocol {
    
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var tokenizationService: TokenizationServiceProtocol
    
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

extension FormViewController: CardScannerViewControllerDelegate {
    func setScannedCardDetails(with cardDetails: PrimerCreditCardDetails) {
        switch formType {
        case .cardForm:
            subview.textFields[0][0].text = cardDetails.name
            let numberMask = Mask(pattern: "#### #### #### ####")
            subview.textFields[1][0].text = numberMask.apply(on: cardDetails.number!)
            guard let year = cardDetails.expiryYear else { return }
            guard let month = cardDetails.expiryMonth else { return }
            subview.textFields[2][0].text = month + "/" + year
        default:
            break
        }
    }
}

//
//  PrimerCardFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/7/21.
//

import UIKit

/// Subclass of the PrimerFormViewController that uses the checkout components and the card components manager
class PrimerCardFormViewController: PrimerFormViewController {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private var cardComponentsManager: CardComponentsManager!
    private var flow: PaymentFlow!
    private var resumeHandler: ResumeHandlerProtocol!
    
    private let cardNumberContainerView = PrimerCustomFieldView()
    private let cardNumberField = PrimerCardNumberFieldView()
    private let expiryDateContainerView = PrimerCustomFieldView()
    private let expiryDateField = PrimerExpiryDateFieldView()
    private let cvvContainerView = PrimerCustomFieldView()
    private let cvvField = PrimerCVVFieldView()
    private let cardholderNameContainerView = PrimerCustomFieldView()
    private let cardholderNameField = PrimerCardholderNameFieldView()
    private let submitButton = PrimerButton()
    private var paymentMethod: PaymentMethodToken?
    
    init(flow: PaymentFlow) {
        self.flow = flow
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Content.PrimerCardFormView.title
        view.backgroundColor = theme.view.backgroundColor
        verticalStackView.spacing = 6
        configureCardNumberField()
        configureExpiryAndCvvRow()
        configureCardholderNameField()
        if flow == .checkout { configureSaveCardSwitch() }
        configureSeparator()
        configureSubmitButton()
        cardComponentsManager = CardComponentsManager(
            flow: flow,
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField
        )
        cardComponentsManager.delegate = self        
    }

    private func configureCardNumberField() {
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.input.text.color
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = self
        cardNumberContainerView.fieldView = cardNumberField
        cardNumberContainerView.placeholderText = "Card number"
        cardNumberContainerView.setup()
        cardNumberContainerView.tintColor = theme.input.border.color(for: .selected)
        verticalStackView.addArrangedSubview(cardNumberContainerView)
    }

    private func configureExpiryAndCvvRow() {
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .fill
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.spacing = 16
        configureExpiryDateField(horizontalStackView)
        configureCvvField((horizontalStackView))
        verticalStackView.addArrangedSubview(horizontalStackView)
    }

    private func configureExpiryDateField(_ view: UIStackView) {
        expiryDateField.placeholder = "02/22"
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.input.text.color
        expiryDateField.delegate = self
        expiryDateContainerView.fieldView = expiryDateField
        expiryDateContainerView.placeholderText = "Expiry"
        expiryDateContainerView.setup()
        expiryDateContainerView.tintColor = theme.input.border.color(for: .selected)
        view.addArrangedSubview(expiryDateContainerView)
    }

    private func configureCvvField(_ view: UIStackView) {
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.input.text.color
        cvvField.delegate = self
        
        cvvContainerView.fieldView = cvvField
        cvvContainerView.placeholderText = "CVV/CVC"
        cvvContainerView.setup()
        cvvContainerView.tintColor = theme.input.border.color(for: .selected)
        view.addArrangedSubview(cvvContainerView)
    }

    private func configureCardholderNameField() {
        cardholderNameField.placeholder = "John Smith"
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.textColor = theme.input.text.color
        cardholderNameField.delegate = self
        cardholderNameContainerView.fieldView = cardholderNameField
        cardholderNameContainerView.placeholderText = "Name"
        cardholderNameContainerView.setup()
        cardholderNameContainerView.tintColor = theme.input.border.color(for: .selected)
        verticalStackView.addArrangedSubview(cardholderNameContainerView)
    }

    private func configureSaveCardSwitch() {
        let saveCardSwitchContainerStackView = UIStackView()
        saveCardSwitchContainerStackView.axis = .horizontal
        saveCardSwitchContainerStackView.alignment = .fill
        saveCardSwitchContainerStackView.spacing = 8.0
        let saveCardSwitch = UISwitch()
        saveCardSwitchContainerStackView.addArrangedSubview(saveCardSwitch)
        let saveCardLabel = UILabel()
        saveCardLabel.text = "Save this card"
        saveCardLabel.textColor = theme.text.body.color
        saveCardLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        saveCardSwitchContainerStackView.addArrangedSubview(saveCardLabel)
        verticalStackView.addArrangedSubview(saveCardSwitchContainerStackView)
        saveCardSwitchContainerStackView.isHidden = true
    }

    private func configureSeparator() {
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        verticalStackView.addArrangedSubview(separatorView)
    }

    private func generateButtonTitle() -> String {
        if flow == .checkout {
            let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
            let amount = viewModel.amountStringed ?? ""
            return Content.PrimerCardFormView.payButtonTitle + " \(amount)"
        } else if flow == .vault {
            return Content.PrimerCardFormView.addCardButtonTitle
        } else {
            return ""
        }
    }

    private func configureSubmitButton() {
        let buttonTitle = generateButtonTitle()
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.isAccessibilityElement = true
        submitButton.accessibilityIdentifier = "submit_btn"
        submitButton.isEnabled = false
        submitButton.setTitle(buttonTitle, for: .normal)
        submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
        submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
        submitButton.layer.cornerRadius = 4
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(payButtonTapped(_:)), for: .touchUpInside)
        verticalStackView.addArrangedSubview(submitButton)
        
        cardComponentsManager = CardComponentsManager(
//            clientToken: state.accessToken,
            flow: flow,
            cardnumberField: cardNumberField,
            expiryDateField: expiryDateField,
            cvvField: cvvField,
            cardholderNameField: cardholderNameField)
        cardComponentsManager.delegate = self        
    }
    
    @objc func payButtonTapped(_ sender: UIButton) {
        cardComponentsManager.tokenize()
    }
}

extension PrimerCardFormViewController: CardComponentsManagerDelegate, PrimerTextFieldViewDelegate {
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        self.paymentMethod = paymentMethodToken
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: strongSelf)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, { err in
                self?.cardComponentsManager.setIsLoading(false)
                
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                if let err = err {
                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismiss()
                    } else {
                        let evc = ErrorViewController(message: err.localizedDescription)
                        evc.view.translatesAutoresizingMaskIntoConstraints = false
                        evc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                        Primer.shared.primerRootVC?.show(viewController: evc)
                    }
                } else {
                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismiss()
                    } else {
                        let svc = SuccessViewController()
                        svc.view.translatesAutoresizingMaskIntoConstraints = false
                        svc.view.heightAnchor.constraint(equalToConstant: 300.0).isActive = true
                        Primer.shared.primerRootVC?.show(viewController: svc)
                    }
                }
                
            })
        }
    }

    func cardComponentsManager(
        _ cardComponentsManager: CardComponentsManager,
        clientTokenCallback completion: @escaping (String?, Error?) -> Void
    ) {
        let state: AppStateProtocol = DependencyContainer.resolve()

        if let clientToken = state.accessToken {
            completion(clientToken, nil)
        } else {
            completion(nil, PrimerError.clientTokenNull)
        }
    }

    func cardComponentsManager(
        _ cardComponentsManager: CardComponentsManager,
        tokenizationFailedWith errors: [Error]
    ) {

    }

    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, isLoading: Bool) {
        submitButton.showSpinner(isLoading)
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = !isLoading
    }

    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        if primerTextFieldView is PrimerCardNumberFieldView {
            cardNumberContainerView.errorText = nil
        } else if primerTextFieldView is PrimerExpiryDateFieldView {
            expiryDateContainerView.errorText = nil
        } else if primerTextFieldView is PrimerCVVFieldView {
            cvvContainerView.errorText = nil
        } else if primerTextFieldView is PrimerCardholderNameFieldView {
            cardholderNameContainerView.errorText = nil
        }
    }

    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        if primerTextFieldView is PrimerCardNumberFieldView, isValid == false {
            cardNumberContainerView.errorText = "Invalid card number"
        } else if primerTextFieldView is PrimerExpiryDateFieldView, isValid == false {
            expiryDateContainerView.errorText = "Invalid date"
        } else if primerTextFieldView is PrimerCVVFieldView, isValid == false {
            cvvContainerView.errorText = "Invalid CVV"
        } else if primerTextFieldView is PrimerCardholderNameFieldView, isValid == false {
            cardholderNameContainerView.errorText = "Invalid name"
        }

        if cardNumberField.isTextValid,
           expiryDateField.isTextValid,
           cvvField.isTextValid,
           cardholderNameField.isTextValid {
            submitButton.isEnabled = true
            submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            submitButton.isEnabled = false
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }

    func primerTextFieldView(
        _ primerTextFieldView: PrimerTextFieldView,
        validationDidFailWithError error: Error
    ) {

    }

    func primerTextFieldView(
        _ primerTextFieldView: PrimerTextFieldView,
        didDetectCardNetwork cardNetwork: CardNetwork
    ) {

    }
}

extension PrimerCardFormViewController: ResumeHandlerProtocol {
    func handle(error: Error) {
        DispatchQueue.main.async {
            self.cardComponentsManager.setIsLoading(false)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let evc = ErrorViewController(message: error.localizedDescription)
                evc.view.translatesAutoresizingMaskIntoConstraints = false
                evc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: evc)
            }
        }
    }
    
    func handle(newClientToken clientToken: String) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if state.accessToken == clientToken {
            let err = PrimerError.invalidValue(key: "clientToken")
            Primer.shared.delegate?.onResumeError?(err)
            handle(error: err)
            return
        }
        
        do {
            try ClientTokenService.storeClientToken(clientToken)
           
            let state: AppStateProtocol = DependencyContainer.resolve()
            let decodedClientToken = state.decodedClientToken!
            
            guard let paymentMethod = paymentMethod else {
                let err = PrimerError.invalidValue(key: "paymentMethod")
                Primer.shared.delegate?.onResumeError?(err)
                handle(error: err)
                return
            }
           
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                #if canImport(Primer3DS)
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethod, protocolVersion: state.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        guard let threeDSPostAuthResponse = paymentMethodToken.1,
                              let resumeToken = threeDSPostAuthResponse.resumeToken else {
                            let err = PrimerError.threeDSFailed
                            Primer.shared.delegate?.onResumeError?(err)
                            self.handle(error: err)
                            return
                        }
                       
                        Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
                       
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        let err = PrimerError.threeDSFailed
                        Primer.shared.delegate?.onResumeError?(err)
                        self.handle(error: err)
                    }
                }
                #else
                let error = PrimerError.threeDSFailed
                Primer.shared.delegate?.onResumeError?(error)
                #endif
               
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken")
                Primer.shared.delegate?.onResumeError?(err)
                handle(error: err)
            }
           
        } catch {
            Primer.shared.delegate?.onResumeError?(error)
            handle(error: error)
        }
    }
    
    func handleSuccess() {
        DispatchQueue.main.async {
            self.cardComponentsManager.setIsLoading(false)
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

            if settings.hasDisabledSuccessScreen {
                Primer.shared.dismiss()
            } else {
                let svc = SuccessViewController()
                svc.view.translatesAutoresizingMaskIntoConstraints = false
                svc.view.heightAnchor.constraint(equalToConstant: 300).isActive = true
                Primer.shared.primerRootVC?.show(viewController: svc)
            }
        }
    }
}

class PrimerCustomFieldView: UIView {

    override var tintColor: UIColor! {
        didSet {
            topPlaceholderLabel.textColor = tintColor
            bottomLine.backgroundColor = tintColor
        }
    }

    var stackView: UIStackView = UIStackView()
    var placeholderText: String?
    var errorText: String? {
        didSet {
            errorLabel.text = errorText ?? ""
        }
    }
    var fieldView: PrimerTextFieldView!
    private let errorLabel = UILabel()
    private let topPlaceholderLabel = UILabel()
    private let bottomLine = UIView()
    private var theme: PrimerThemeProtocol = DependencyContainer.resolve()

    func setup() {
        addSubview(stackView)
        stackView.alignment = .fill
        stackView.axis = .vertical

        topPlaceholderLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        topPlaceholderLabel.text = placeholderText
        topPlaceholderLabel.textColor = theme.text.system.color
        topPlaceholderLabel.textAlignment = .left
        stackView.addArrangedSubview(topPlaceholderLabel)

        let textFieldStackView = UIStackView()
        textFieldStackView.alignment = .fill
        textFieldStackView.axis = .vertical
        textFieldStackView.addArrangedSubview(fieldView)
        textFieldStackView.spacing = 0
        bottomLine.backgroundColor = theme.text.system.color
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(textFieldStackView)
        stackView.addArrangedSubview(bottomLine)

        errorLabel.textColor = theme.input.errortext.color
        errorLabel.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        errorLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        errorLabel.text = nil
        errorLabel.textAlignment = .right

        stackView.addArrangedSubview(errorLabel)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
    }

}

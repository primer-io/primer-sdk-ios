//
//  FormTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

internal class Input {
    var name: String?
    var topPlaceholder: String?
    var textFieldPlaceholder: String?
    var keyboardType: UIKeyboardType?
    var allowedCharacterSet: CharacterSet?
    var maxCharactersAllowed: UInt?
    var isValid: ((_ text: String) -> Bool?)?
    var descriptor: String?
    var text: String? {
        return primerTextFieldView?.text
    }
    var primerTextFieldView: PrimerTextFieldView?
}

class FormPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var flow: PaymentFlow
    private var cardComponentsManager: CardComponentsManager!
    var onConfigurationFetched: (() -> Void)?
    
    // FIXME: Is this the fix for the button's indicator?
    private var isTokenizing = false
    
    private lazy var _title: String = { return "Payment Card" }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonTitle: String? = {
        switch config.type {
        case .paymentCard:
            return (Primer.shared.flow?.internalSessionFlow.vaulted == true)
            ? NSLocalizedString("payment-method-type-card-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: "Add new card",
                                comment: "Add new card - Payment Method Type (Card Vaulted)")
            
            : NSLocalizedString("payment-method-type-card-not-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: "Pay with card",
                                comment: "Pay with card - Payment Method Type (Card Not vaulted)")
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTitle: String? {
        get { return _buttonTitle }
        set { _buttonTitle = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .adyenBlik:
            return UIImage(named: "blik-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonImage: UIImage? {
        get { return _buttonImage }
        set { _buttonImage = newValue }
    }
    
    private lazy var _buttonColor: UIColor? = {
        switch config.type {
        case .adyenBlik:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonColor: UIColor? {
        get { return _buttonColor }
        set { _buttonColor = newValue }
    }

    private lazy var _buttonTitleColor: UIColor? = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTitleColor: UIColor? {
        get { return _buttonTitleColor }
        set { _buttonTitleColor = newValue }
    }
    
    private lazy var _buttonBorderWidth: CGFloat = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    override var buttonBorderWidth: CGFloat {
        get { return _buttonBorderWidth }
        set { _buttonBorderWidth = newValue }
    }
    
    private lazy var _buttonBorderColor: UIColor? = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonBorderColor: UIColor? {
        get { return _buttonBorderColor }
        set { _buttonBorderColor = newValue }
    }
    
    private lazy var _buttonTintColor: UIColor? = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTintColor: UIColor? {
        get { return _buttonTintColor }
        set { _buttonTintColor = newValue }
    }
    
    private var isCardholderNameFieldEnabled: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if (state.primerConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first?.options as? PrimerConfiguration.CheckoutModule.CardInformationOptions)?.cardHolderName == false {
            return false
        } else {
            return true
        }
    }
    
    lazy var cardNumberField: PrimerCardNumberFieldView = {
        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.input.text.color
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = self
        return cardNumberField
    }()
    
    var requirePostalCode: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let billingAddressModule = state.primerConfiguration?.checkoutModules?.filter({ $0.type == "BILLING_ADDRESS" }).first else { return false }
        return (billingAddressModule.options as? PrimerConfiguration.CheckoutModule.PostalCodeOptions)?.postalCode ?? false
    }
    
    var requireCardHolderName: Bool {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let cardHolderNameModule = state.primerConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first else { return false }
        return (cardHolderNameModule.options as? PrimerConfiguration.CheckoutModule.CardInformationOptions)?.cardHolderName ?? false
    }
    
    lazy var expiryDateField: PrimerExpiryDateFieldView = {
        let expiryDateField = PrimerExpiryDateFieldView()
        expiryDateField.placeholder = "02/22"
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.input.text.color
        expiryDateField.delegate = self
        return expiryDateField
    }()
    
    lazy var cvvField: PrimerCVVFieldView = {
        let cvvField = PrimerCVVFieldView()
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.input.text.color
        cvvField.delegate = self
        return cvvField
    }()
    
    lazy var cardholderNameField: PrimerCardholderNameFieldView? = {
        if !isCardholderNameFieldEnabled { return nil }
        let cardholderNameField = PrimerCardholderNameFieldView()
        cardholderNameField.placeholder = NSLocalizedString("primer-form-text-field-placeholder-cardholder",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "e.g. John Doe",
                                                            comment: "e.g. John Doe - Form Text Field Placeholder (Cardholder name)")
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.textColor = theme.input.text.color
        cardholderNameField.delegate = self
        return cardholderNameField
    }()
    
    var inputTextFieldsStackViews: [UIStackView] {
        var stackViews: [UIStackView] = []
        for input in self.inputs {
            let stackView = UIStackView()
            stackView.spacing = 2
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.distribution = .fill

            let inputTextFieldView = PrimerGenericFieldView()
            inputTextFieldView.delegate = self
            inputTextFieldView.translatesAutoresizingMaskIntoConstraints = false
            inputTextFieldView.heightAnchor.constraint(equalToConstant: 35).isActive = true
            inputTextFieldView.textField.keyboardType = input.keyboardType ?? .default
            inputTextFieldView.allowedCharacterSet = input.allowedCharacterSet
            inputTextFieldView.maxCharactersAllowed = input.maxCharactersAllowed
            inputTextFieldView.isValid = input.isValid
            inputTextFieldView.shouldMaskText = false
            input.primerTextFieldView = inputTextFieldView
            
            let inputContainerView = PrimerCustomFieldView()
            inputContainerView.fieldView = inputTextFieldView
            inputContainerView.placeholderText = input.topPlaceholder
            inputContainerView.setup()
            inputContainerView.tintColor = .systemBlue
            stackView.addArrangedSubview(inputContainerView)
            
            if let descriptor = input.descriptor {
                let lbl = UILabel()
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = descriptor
                stackView.addArrangedSubview(lbl)
            }
            stackViews.append(stackView)
        }
        
        return stackViews
    }

    
    var onClientSessionActionCompletion: ((Error?) -> Void)?
    var onResumeHandlerCompletion: ((URL?, Error?) -> Void)?
    var onResumeTokenCompletion: ((Error?) -> Void)?
    private var isCanceled: Bool = false

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init(config: PaymentMethodConfig) {
        self.flow = .checkout
        if let flow = Primer.shared.flow, flow.internalSessionFlow.vaulted {
            self.flow = .vault
        }
        super.init(config: config)
        
        switch config.type {
        case .adyenBlik:
            let input1 = Input()
            input1.name = "OTP"
            input1.topPlaceholder = NSLocalizedString(
                "input_hint_form_blik_otp",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "6 digit code",
                comment: "6 digit code - Text field top placeholder")
            input1.textFieldPlaceholder = NSLocalizedString(
                "payment_method_blik_loading_placeholder",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Enter your one time password",
                comment: "Enter your one time password - Text field placeholder")
            input1.keyboardType = .numberPad
            input1.descriptor = NSLocalizedString(
                "input_description_otp",
                tableName: nil,
                bundle: Bundle.primerResources,
                value: "Get the code from your banking app.",
                comment: "Get the code from your banking app - Blik descriptor")
            input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
            input1.maxCharactersAllowed = 6
            input1.isValid = { text in
                return text.isNumeric && text.count >= 6
            }
            inputs.append(input1)
            
        default:
            break
        }
    }
    
    required init(config: PaymentMethodConfig) {
        self.flow = .checkout
        if let flow = Primer.shared.flow, flow.internalSessionFlow.vaulted {
            self.flow = .vault
        }
        
        super.init(config: config)
        
        let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
        ErrorHandler.handle(error: err)
        self.completion?(nil, err)
        self.completion = nil
    }
    
    override func validate() throws {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "clientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if !Primer.shared.flow.internalSessionFlow.vaulted {
            if settings.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if settings.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: event)
        
        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
        
        if Primer.shared.delegate?.onClientSessionActions != nil {
            let params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            ClientSession.Action.selectPaymentMethod(resumeHandler: self, withParameters: params)
        } else {
            continueTokenizationFlow()
        }
    }
    
    fileprivate func continueTokenizationFlow() {
        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        DispatchQueue.main.async {
            switch self.config.type {
            case .adyenBlik:
                let input = self.inputs.first!
                let pcfvc = PrimerInputViewController(navigationBarLogo: UIImage(named: "blik-logo-black", in: Bundle.primerResources, compatibleWith: nil), formPaymentMethodTokenizationViewModel: self)
                Primer.shared.primerRootVC?.show(viewController: pcfvc)
                
            default:
                break
            }
        }
    }
    
    fileprivate func enableConfirmButton(_ flag: Bool) {
        submitButton.isEnabled = flag
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        submitButton.backgroundColor = flag ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
    }
    
    @objc
    func payButtonTapped(_ sender: UIButton) {
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .submit,
                objectClass: "\(Self.self)",
                place: .cardForm))
        Analytics.Service.record(event: viewEvent)
        
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = false
        
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            var network = self.cardNetwork?.rawValue.uppercased()
            if network == nil || network == "UNKNOWN" {
                network = "OTHER"
            }
            
            let params: [String: Any] = [
                "paymentMethodType": "PAYMENT_CARD",
                "binData": [
                    "network": network,
                ]
            ]
    
            onClientSessionActionCompletion = { err in
                if let err = err {
                    DispatchQueue.main.async {
                        self.submitButton.showSpinner(false)
                        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
                        PrimerDelegateProxy.onResumeError(err)
                    }
                    self.handle(error: err)
                } else {
                    self.cardComponentsManager.tokenize()
                }
                
                return self.startPolling(on: pollingUrl)
            }.then { resumeToken -> Promise<Void> in
                return self.passResumeToken(resumeToken)
            }
            .done {
                self.completion?(self.paymentMethod, nil)
                self.completion = nil
            }
            .ensure {
                Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
                self.onClientSessionActionCompletion = nil
                self.onResumeHandlerCompletion = nil
                self.onResumeTokenCompletion = nil
            }
            .catch { err in
                self.handleFailedTokenizationFlow(error: err)
                self.submitButton.showSpinner(false)
                self.completion?(nil, err)
                self.completion = nil
            }
            
        default:
            break
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, onTokenizeSuccess paymentMethodToken: PaymentMethodToken) {
        self.paymentMethod = paymentMethodToken
        
        DispatchQueue.main.async {
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethodToken, resumeHandler: self)
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethodToken, { err in
                self.cardComponentsManager.setIsLoading(false)
                
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            }
        }
    }
    
    func cardComponentsManager(_ cardComponentsManager: CardComponentsManager, tokenizationFailedWith errors: [Error]) {
        submitButton.showSpinner(false)
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        
        DispatchQueue.main.async {
            let err = PrimerError.underlyingErrors(errors: errors, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            PrimerDelegateProxy.checkoutFailed(with: err)
            self.handleFailedTokenizationFlow(error: err)
        }
    }
    
    private func startPolling(on url: URL) -> Promise<String> {
        return Promise { seal in
            self.startPolling(on: url) { (id, err) in
                if let err = err {
                    seal.reject(err)
                } else if let id = id {
                    seal.fulfill(id)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
        }
    }
    
    private func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
            if self.completion == nil {
                let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(nil, err)
                return
            }
            
            switch result {
            case .success(let res):
                if res.status == .pending {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.generic(message: "Should never end up here", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                }
            case .failure(let err):
                ErrorHandler.handle(error: err)
                // Retry
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                    self.startPolling(on: url, completion: completion)
                }
            }
        }
    }
    
    fileprivate func enableSubmitButtonIfNeeded() {
        var validations = [
            cardNumberField.isTextValid,
            expiryDateField.isTextValid,
            cvvField.isTextValid
        ]

        if requirePostalCode { validations.append(postalCodeField.isTextValid) }
        if let cardholderNameField = cardholderNameField, requireCardHolderName { validations.append(cardholderNameField.isTextValid) }

        if validations.allSatisfy({ $0 == true }) {
            submitButton.isEnabled = true
            submitButton.backgroundColor = theme.mainButton.color(for: .enabled)
        } else {
            submitButton.isEnabled = false
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
        }
    }
    
}

extension FormPaymentMethodTokenizationViewModel: PrimerTextFieldViewDelegate {
    
    func primerTextFieldViewDidBeginEditing(_ primerTextFieldView: PrimerTextFieldView) {
        if let input = inputs.filter({ $0.primerTextFieldView == primerTextFieldView }).first {
            
        }
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        let isTextsValid = inputs.compactMap({ $0.primerTextFieldView?.isTextValid })
        
        if isTextsValid.contains(false) {
            enableConfirmButton(false)
        } else {
            enableConfirmButton(true)
        }
    }
    
    func primerTextFieldViewShouldBeginEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        return true
    }
    
    func primerTextFieldViewShouldEndEditing(_ primerTextFieldView: PrimerTextFieldView) -> Bool {
        if let input = inputs.filter({ $0.primerTextFieldView == primerTextFieldView }).first {
            
        }
        return true
    }
    
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, validationDidFailWithError error: Error) {
        
    }
    
    func primerTextFieldViewDidEndEditing(_ primerTextFieldView: PrimerTextFieldView) {

    }
    
}

extension FormPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        DispatchQueue.main.async {
            if self.onClientSessionActionCompletion != nil {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                self.onClientSessionActionCompletion?(error)
                self.onClientSessionActionCompletion = nil
            }
            
            if self.onResumeHandlerCompletion != nil {
                self.onResumeHandlerCompletion?(nil, error)
                self.onResumeHandlerCompletion = nil
            }
            
            if self.onResumeTokenCompletion != nil {
                self.onResumeTokenCompletion?(error)
                self.onResumeTokenCompletion = nil
            }
        }
    }
    
    override func handle(newClientToken clientToken: String) {
        do {
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            if state.clientToken != clientToken {
                try ClientTokenService.storeClientToken(clientToken)
            }
            
            let decodedClientToken = ClientTokenService.decodedClientToken!
            
            if decodedClientToken.intent == RequiredActionName.threeDSAuthentication.rawValue {
                #if canImport(Primer3DS)
                guard let paymentMethod = paymentMethod else {
                    DispatchQueue.main.async {
                        let err = ParserError.failedToDecode(message: "Failed to find paymentMethod", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: containerErr)
                        PrimerDelegateProxy.onResumeError(containerErr)
                    }
                    return
                }
                
                let threeDSService = ThreeDSService()
                threeDSService.perform3DS(paymentMethodToken: paymentMethod, protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2, sdkDismissed: nil) { result in
                    switch result {
                    case .success(let paymentMethodToken):
                        DispatchQueue.main.async {
                            guard let threeDSPostAuthResponse = paymentMethodToken.1,
                                  let resumeToken = threeDSPostAuthResponse.resumeToken else {
                                      DispatchQueue.main.async {
                                          let decoderError = ParserError.failedToDecode(message: "Failed to decode the threeDSPostAuthResponse", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                          let err = PrimerError.failedToPerform3DS(error: decoderError, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                                          ErrorHandler.handle(error: err)
                                          PrimerDelegateProxy.onResumeError(err)
                                          self.handle(error: err)
                                      }
                                      return
                                  }
                            
                            PrimerDelegateProxy.onResumeSuccess(resumeToken, resumeHandler: self)
                        }
                        
                    case .failure(let err):
                        log(logLevel: .error, message: "Failed to perform 3DS with error \(err as NSError)")
                        let containerErr = PrimerError.failedToPerform3DS(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: containerErr)
                        DispatchQueue.main.async {
                            PrimerDelegateProxy.onResumeError(containerErr)
                        }
                    }
                }
                #else
                let err = PrimerError.failedToPerform3DS(error: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async {
                    PrimerDelegateProxy.onResumeError(err)
                }
                #endif
                
            } else if decodedClientToken.intent == RequiredActionName.checkout.rawValue {
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self.continueTokenizationFlow()
                }
                .catch { err in
                    DispatchQueue.main.async {
                        Primer.shared.delegate?.onResumeError?(err)
                    }
                    self.handle(error: err)
                }
            } else {
                let err = PrimerError.invalidValue(key: "resumeToken", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                
                handle(error: err)
                DispatchQueue.main.async {
                    PrimerDelegateProxy.onResumeError(err)
                }
            }
            
        } catch {
            handle(error: error)
            DispatchQueue.main.async {
                PrimerDelegateProxy.onResumeError(error)
            }
        }
    }
    
    override func handleSuccess() {
        DispatchQueue.main.async {
            self.submitButton.showSpinner(false)
            Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
            
            if self.onResumeTokenCompletion != nil {
                self.onResumeTokenCompletion?(nil)
                self.onResumeTokenCompletion = nil
            }
        }
    }
}

#endif


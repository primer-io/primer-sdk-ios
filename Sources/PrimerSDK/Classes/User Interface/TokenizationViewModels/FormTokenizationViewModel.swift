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
    var inputs: [Input] = []

    override lazy var title: String = {
        return "Form"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .blik:
            return UIImage(named: "blik-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .blik:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    override lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    lazy var submitButton: PrimerOldButton = {
        let btn = PrimerOldButton()
        btn.isEnabled = false
        btn.clipsToBounds = true
        btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        btn.layer.cornerRadius = 4
        btn.backgroundColor = btn.isEnabled ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
        btn.setTitle("Confirm", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        return btn
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
        case .blik:
            let input1 = Input()
            input1.name = "OTP"
            input1.topPlaceholder = "6 digit code"
            input1.textFieldPlaceholder = "Enter your one time password"
            input1.keyboardType = .numberPad
            input1.descriptor = "Get the code from your banking app."
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
    
    func cancel() {
        Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
        self.onClientSessionActionCompletion = nil
        self.onResumeHandlerCompletion = nil
        self.onResumeTokenCompletion = nil
        
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
                Primer.shared.delegate?.checkoutFailed?(with: error)
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
        self.onClientSessionActionCompletion = nil
        
        DispatchQueue.main.async {
            switch self.config.type {
            case .blik:
                let input1 = Input()
                input1.name = "OTP"
                input1.topPlaceholder = "6 digit code"
                input1.textFieldPlaceholder = "Enter your one time password"
                input1.keyboardType = .numberPad
                input1.descriptor = "Get the code from your banking app."
                input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
                input1.maxCharactersAllowed = 6
                input1.isValid = { text in
                    return text.isNumeric && text.count >= 6
                }
                
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
        
        switch config.type {
        case .blik:
            self.submitButton.showSpinner(true)
            
            firstly {
                return self.tokenize()
            }.then { paymentMethodToken -> Promise<URL> in
                self.paymentMethod = paymentMethodToken
                return self.fetchPollingUrl(for: paymentMethodToken)
            }.then { pollingUrl -> Promise<String> in
                self.onResumeHandlerCompletion = nil
                
                DispatchQueue.main.async {
                    Primer.shared.primerRootVC?.view.isUserInteractionEnabled = true
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
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
    
    private func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let blikCode = inputs.first?.text else {
                let err = PrimerError.invalidValue(key: "blikCode", value: nil, userInfo: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            let tokenizationRequest = BlikPaymentMethodTokenizationRequest(
                paymentInstrument: BlikPaymentMethodOptions(
                    paymentMethodType: config.type,
                    paymentMethodConfigId: configId,
                    sessionInfo: BlikPaymentMethodOptions.SessionInfo(
                        blikCode: blikCode,
                        locale: settings.localeData.localeCode ?? "en-UK")))

            let apiClient = PrimerAPIClient()
            apiClient.tokenizePaymentMethod(clientToken: decodedClientToken, paymentMethodTokenizationRequest: tokenizationRequest) { result in
                switch result {
                case .success(let paymentMethodToken):
                    seal.fulfill(paymentMethodToken)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func fetchPollingUrl(for paymentMethodToken: PaymentMethodToken) -> Promise<URL> {
        return Promise { seal in
            self.onResumeHandlerCompletion = { (pollingUrl, err) in
                if let err = err {
                    seal.reject(err)
                } else if let pollingUrl = pollingUrl {
                    seal.fulfill(pollingUrl)
                }
            }
            
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethodToken, resumeHandler: self)
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
    
    private func passResumeToken(_ resumeToken: String) -> Promise<Void> {
        return Promise { seal in
            self.onResumeTokenCompletion = { err in
                if let err = err {
                    seal.reject(err)
                } else {
                    seal.fulfill()
                }
            }
            
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
            }
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
            
            if decodedClientToken.intent?.contains("_REDIRECTION") == true,
               let statusUrlStr = decodedClientToken.statusUrl,
               let statusUrl = URL(string: statusUrlStr) {
                self.onResumeHandlerCompletion?(statusUrl, nil)
                self.onResumeHandlerCompletion
                
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
                    Primer.shared.delegate?.onResumeError?(err)
                }
            }
            
        } catch {
            handle(error: error)
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeError?(error)
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


//
//  QRCodeTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/1/22.
//

#if canImport(UIKit)

import SafariServices
import UIKit

class QRCodeTokenizationViewModel: ExternalPaymentMethodTokenizationViewModel {
    
    override lazy var title: String = {
        switch config.type {
        case .xfers:
            return "XFers"
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .xfers:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .xfers:
            return UIImage(named: "xfers-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .xfers:
            return UIColor(red: 2.0/255, green: 139.0/255, blue: 244.0/255, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .xfers:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .xfers:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .xfers:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .xfers:
            return nil
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
    
    private var tokenizationService: TokenizationServiceProtocol?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
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
                place: .bankSelectionList))
        Analytics.Service.record(event: event)
    }
    
    fileprivate func continueTokenizationFlow() {
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        let qcvc = QRCodeViewController(viewModel: self)
        Primer.shared.primerRootVC?.show(viewController: qcvc)
        
//        firstly {
//            self.fetchBanks()
//        }
//        .then { banks -> Promise<PaymentMethodToken> in
//            self.banks = banks
//            self.dataSource = banks
//            let bsvc = BankSelectorViewController(viewModel: self)
//            DispatchQueue.main.async {
//                Primer.shared.primerRootVC?.show(viewController: bsvc)
//            }
//
//            return self.fetchPaymentMethodToken()
//        }
//        .then { tmpPaymentMethod -> Promise<PaymentMethodToken> in
//            self.paymentMethod = tmpPaymentMethod
//            return self.continueTokenizationFlow(for: tmpPaymentMethod)
//        }
//        .done { paymentMethod in
//            self.paymentMethod = paymentMethod
//
//            DispatchQueue.main.async {
//                if Primer.shared.flow.internalSessionFlow.vaulted {
//                    Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
//                }
//
//                self.completion?(self.paymentMethod, nil)
//                self.handleSuccessfulTokenizationFlow()
//            }
//        }
//        .ensure { [unowned self] in
//            DispatchQueue.main.async {
//                self.willDismissExternalView?()
//                self.webViewController?.dismiss(animated: true, completion: {
//                    self.didDismissExternalView?()
//                })
//            }
//
//            self.willPresentExternalView = nil
//            self.didPresentExternalView = nil
//            self.willDismissExternalView = nil
//            self.didDismissExternalView = nil
//            self.webViewController = nil
//            self.webViewCompletion = nil
//            self.onResumeTokenCompletion = nil
//            self.onClientToken = nil
//        }
//        .catch { err in
//            DispatchQueue.main.async {
//                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
//                Primer.shared.delegate?.checkoutFailed?(with: err)
//                self.handleFailedTokenizationFlow(error: err)
//            }
//        }
    }
    
    
}

extension QRCodeTokenizationViewModel {
    
    override func handle(error: Error) {
        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        self.completion?(nil, error)
        self.completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        do {
            // For Apaya there's no redirection URL, once the webview is presented it will get its response from a URL redirection.
            // We'll end up in here only for surcharge.
            
            guard let decodedClientToken = clientToken.jwtTokenPayload else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                self.handle(error: err)
                return
            }
            
            if decodedClientToken.intent?.contains("_REDIRECTION") == true {
                super.handle(newClientToken: clientToken)
            } else if decodedClientToken.intent == "CHECKOUT" {
                try ClientTokenService.storeClientToken(clientToken)
                
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self.continueTokenizationFlow()
                }
                .catch { err in
                    self.handle(error: err)
                }
            } else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                self.handle(error: err)
                return
            }
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeError?(error)
                self.handle(error: error)
            }
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif


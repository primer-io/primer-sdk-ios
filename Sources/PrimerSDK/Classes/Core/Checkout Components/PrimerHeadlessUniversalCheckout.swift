//
//  PrimerHeadlessUniversalCheckout.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import UIKit

public typealias PrimerPaymentMethodType = PaymentMethodConfigType

public class PrimerHeadlessUniversalCheckout {
    
    public weak var delegate: PrimerHeadlessUniversalCheckoutDelegate?
    private(set) public var clientToken: String?
    public static let current = PrimerHeadlessUniversalCheckout()
    
    fileprivate init() {}
    
    public func start(withClientToken clientToken: String, settings: PrimerSettings? = nil, delegate: PrimerHeadlessUniversalCheckoutDelegate? = nil, completion: @escaping (_ paymentMethodTypes: [PrimerPaymentMethodType]?, _ err: Error?) -> Void) {
        
        if delegate != nil {
            PrimerHeadlessUniversalCheckout.current.delegate = delegate
        }
        
        guard PrimerHeadlessUniversalCheckout.current.delegate != nil else {
            let err = PrimerError.missingPrimerCheckoutComponentsDelegate(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            DispatchQueue.main.async {
                completion(nil, err)
            }
            return
        }
                        
        if let settings = settings {
            DependencyContainer.register(settings as PrimerSettingsProtocol)
        }
        
        firstly {
            return ClientTokenService.storeClientToken(clientToken)
        }
        .then { () -> Promise<Void> in
            PrimerHeadlessUniversalCheckout.current.clientToken = clientToken
            let primerConfigurationService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            return primerConfigurationService.fetchConfig()
        }
        .done {
            let availablePaymentMethodsTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes()
            if (availablePaymentMethodsTypes ?? []).isEmpty {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                DispatchQueue.main.async {
                    completion(nil, err)
                }
            } else {
                DispatchQueue.main.async {
                    completion(availablePaymentMethodsTypes, nil)
                }
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                completion(nil, err)
            }
        }
    }
    
    private func continueValidateSession() -> Promise<Void> {
        
        return Promise { seal in
            
            let appState: AppStateProtocol = DependencyContainer.resolve()

            guard let clientToken = appState.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let decodedClientToken = clientToken.jwtTokenPayload else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"])
                seal.reject(err)
                return
            }
            
            do {
                try decodedClientToken.validate()
            } catch {
                seal.reject(error)
            }
            
            guard let apiConfiguration = appState.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                seal.reject(err)
                return
            }
            
            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                seal.reject(err)
                return
            }
            
            seal.fulfill()
        }
    }
    
    internal func validateSession() -> Promise<Void> {
        
        return Promise { seal in
            
            let appState: AppStateProtocol = DependencyContainer.resolve()
            
            if appState.clientToken == nil, let clientToken = PrimerHeadlessUniversalCheckout.current.clientToken {
                
                firstly {
                    ClientTokenService.storeClientToken(clientToken)
                }
                .then({ () -> Promise<Void> in
                    self.continueValidateSession()
                })
                .catch { error in
                    seal.reject(error)
                }
                
            } else {
                
                firstly {
                    continueValidateSession()
                }
                .done({ () -> Void in
                    seal.fulfill()
                })
                .catch { error in
                    seal.reject(error)
                }
            }
        }
    }

    internal func listAvailablePaymentMethodsTypes() -> [PrimerPaymentMethodType]? {
        return PrimerAPIConfiguration.paymentMethodConfigs?.compactMap({ $0.type })
    }
    
    public func listRequiredInputElementTypes(for paymentMethodType: PaymentMethodConfigType) -> [PrimerInputElementType]? {
        switch paymentMethodType {
        case .adyenAlipay:
            return []
        case .adyenBlik:
            return []
        case .adyenDotPay:
            return []
        case .adyenGiropay:
            return []
        case .adyenIDeal:
            return []
        case .adyenInterac:
            return []
        case .adyenMobilePay:
            return []
        case .adyenPayTrail:
            return []
        case .adyenSofort:
            return []
        case .adyenTrustly:
            return []
        case .adyenTwint:
            return []
        case .adyenVipps:
            return []
        case .apaya:
            return []
        case .applePay:
            return []
        case .atome:
            return []
        case .buckarooBancontact:
            return []
        case .buckarooEps:
            return []
        case .buckarooGiropay:
            return []
        case .buckarooIdeal:
            return []
        case .buckarooSofort:
            return []
        case .goCardlessMandate:
            return []
        case .googlePay:
            return []
        case .hoolah:
            return []
        case .klarna:
            return []
        case .mollieBankcontact:
            return []
        case .mollieIdeal:
            return []
        case .payNLBancontact:
            return []
        case .payNLGiropay:
            return []
        case .payNLIdeal:
            return []
        case .payNLPayconiq:
            return []
        case .paymentCard:
            let appState: AppStateProtocol = DependencyContainer.resolve()

            var requiredFields: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]
            
            if let checkoutModule = appState.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first,
               let options = checkoutModule.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions {
                if options.cardHolderName == true {
                    requiredFields.append(.cardholderName)
                }
            }
            
            return requiredFields
        case .payPal:
            return []
        case .xfers:
            return []
        case .other(_):
            return []
        }
    }
    
    public static func makeButton(for paymentMethodType: PrimerPaymentMethodType) -> UIButton? {
        guard let paymentMethodConfigs = PrimerAPIConfiguration.paymentMethodConfigs else { return nil }
        guard let paymentMethodConfig = paymentMethodConfigs.filter({ $0.type == paymentMethodType }).first else { return nil }
        return paymentMethodConfig.tokenizationViewModel?.paymentMethodButton
    }

    public static func getAsset(for brand: PrimerAsset.Brand, assetType: PrimerAsset.ImageType) -> UIImage? {
        return brand.getImage(assetType: assetType)
    }
    
    public static func getAsset(for paymentMethodType: PaymentMethodConfigType, assetType: PrimerAsset.ImageType) -> UIImage? {
        return PrimerAsset.getAsset(for: paymentMethodType, assetType: assetType)
    }
    
    public static func getAsset(for cardNetwork: CardNetwork, assetType: PrimerAsset.ImageType) -> UIImage? {
        return PrimerAsset.getAsset(for: cardNetwork, assetType: assetType)
    }
    
    public func showPaymentMethod(_ paymentMethod: PaymentMethodConfigType) {
        DispatchQueue.main.async {
            
            var settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            settings.hasDisabledSuccessScreen = true
            settings.isInitialLoadingHidden = true
            
            switch paymentMethod {
            case .goCardlessMandate,
                    .paymentCard,
                    .other:
                let err = PrimerError.missingCustomUI(paymentMethod: paymentMethod, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: err)
                return
            case .applePay:
                if settings.merchantIdentifier == nil {
                    let err = PrimerError.invalidMerchantIdentifier(merchantIdentifier: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: err)
                    return
                }
            case .payPal:
                if settings.urlScheme == nil {
                    let err = PrimerError.invalidUrlScheme(urlScheme: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutUniversalCheckoutDidFail(withError: err)
                    return
                }
            default:
                break
            }
            
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPreparationStarted()
            
            Primer.shared.showPaymentMethod(paymentMethod, withIntent: .checkout, on: UIViewController())
        }
    }
}

public struct PrimerAsset {
    
    public static func getAsset(for brand: PrimerAsset.Brand, assetType: PrimerAsset.ImageType) -> UIImage? {
        return brand.getImage(assetType: assetType)
    }
    
    public static func getAsset(for paymentMethodType: PaymentMethodConfigType, assetType: PrimerAsset.ImageType) -> UIImage? {
        var brand: PrimerAsset.Brand?
        
        switch paymentMethodType {
        case .adyenAlipay:
            brand = .aliPay
        case .adyenBlik:
            brand = .blik
        case .adyenDotPay:
            brand = .dotPay
        case .adyenGiropay,
                .buckarooGiropay,
                .payNLGiropay:
            brand = .giroPay
        case .adyenIDeal,
                .buckarooIdeal,
                .mollieIdeal,
                .payNLIdeal:
            brand = .iDeal
        case .adyenInterac:
            brand = .interac
        case .adyenMobilePay:
            brand = .mobilePay
        case .adyenPayTrail:
            brand = .payTrail
        case .adyenSofort,
                .buckarooSofort:
            brand = .sofort
        case .adyenTrustly:
            brand = .trustly
        case .adyenTwint:
            brand = .twint
        case .adyenVipps:
            brand = .vipps
        case .apaya:
            brand = .apaya
        case .applePay:
            brand = .applePay
        case .atome:
            brand = .atome
        case .buckarooBancontact,
                .mollieBankcontact,
                .payNLBancontact:
            brand = .bankcontact
        case .buckarooEps:
            brand = .eps
        case .goCardlessMandate:
            brand = .goCardless
        case .googlePay:
            brand = .googlePay
        case .hoolah:
            brand = .hoolah
        case .klarna:
            brand = .klarna
        case .payNLPayconiq:
            brand = .payconiq
        case .paymentCard:
            return nil
        case .payPal:
            brand = .payPal
        case .xfers:
            brand = .xfers
        case .other:
            return nil
        }
        
        return brand?.getImage(assetType: assetType)
    }
    
    public static func getAsset(for cardNetwork: CardNetwork, assetType: PrimerAsset.ImageType) -> UIImage? {
        var brand: PrimerAsset.Brand?
        
        switch cardNetwork {
        case .amex:
            brand = .amex
        case .bancontact:
            brand = .bankcontact
        case .discover:
            brand = .discover
        case .jcb:
            brand = .jcb
        case .masterCard:
            brand = .masterCard
        case .visa:
            brand = .visa
        case .diners,
                .elo,
                .hiper,
                .hipercard,
                .maestro,
                .mir,
                .unionpay,
                .unknown:
            return nil
        }
        
        return brand?.getImage(assetType: assetType)
    }
    
    public enum Brand: String, CaseIterable {
        case adyen, afterPay = "after-pay", aliPay = "ali-pay", alma, amazonPay = "amazon-pay", amex, apaya, applePay = "apple-pay", atome
        case bankcontact, banked, bizum, blik, bolt, boost, braintree, bridge, buckaroo
        case change, checkoutCom = "checkout", clearPay = "clear-pay", coinBase = "coinbase", coinPayments = "coinpayments"
        case dLocal = "d-local", directDebit = "direct-debit", discover, dotPay = "dotpay", eMerchantPay = "emerchantpay", eps, fintecture, fonoa, forter, fpx
        case gCash = "gcash", giroPay = "giropay", globalPayments = "global-payments", goCardless = "go-cardless", googlePay = "google-pay", grabPay = "grab-pay"
        case hoolah
        case iDeal = "ideal", interac
        case ingenico
        case jcb
        case klarna, kount
        case layBuy = "lay-buy", looker
        case masterCard = "master-card", mbWay = "mb-way", mercadoPago = "mercado-pago", metamask, mobilePay = "mobile-pay", mollie
        case neonomics, netSuite = "netsuite", nexi, nuvei
        case p24, payNL = "pay-nl", payconiq, payNow = "paynow", payPal = "paypal", primer, printful, payTrail = "paytrail"
        case ravelin, riskified
        case seon, sepa, sift, signifyd, sofort, stitch, stripe, swish
        case tableau, taxjar, telserv, tink, trilo, trueLayer = "truelayer", trueMoney = "truemoney", trustly, twillio, twint
        case vipps, visa, volt, voucherify, vyne
        case wordline, worldPay = "worldpay"
        case xfers
        
        public func getImage(assetType: PrimerAsset.ImageType) -> UIImage? {
            var imageName = rawValue
            
            switch assetType {
            case .logo:
                imageName += "-logo"
            case .icon:
                imageName += "-icon"
            }
            
            guard let image = UIImage(named: imageName, in: Bundle.primerResources, compatibleWith: nil) else { return nil }
            return image
        }
    }
    
    public enum ImageType: String, CaseIterable, Equatable {
        case logo, icon
    }
    
    public enum ImageColor: String, CaseIterable, Equatable {
        case original, light, dark
    }
}

extension PrimerHeadlessUniversalCheckout {
    internal class Delegate: NSObject, UITextFieldDelegate {
        
        private var inputElement: PrimerInputElement
        private weak var inputElementDelegate: PrimerInputElementDelegate?
        private var detectedType: Any?
        
        init(inputElement: PrimerInputElement, inputElementDelegate: PrimerInputElementDelegate) {
            self.inputElement = inputElement
            self.inputElementDelegate = inputElementDelegate
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            guard let inputElementShouldFocus = self.inputElementDelegate?.inputElementShouldFocus?(self.inputElement) else { return true }
            return inputElementShouldFocus
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            self.inputElementDelegate?.inputElementDidFocus?(self.inputElement)
        }
        
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            guard let inputElementShouldBlur = self.inputElementDelegate?.inputElementShouldBlur?(self.inputElement) else { return true }
            return inputElementShouldBlur
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            self.inputElementDelegate?.inputElementDidBlur?(self.inputElement)
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let primerCheckoutComponentsTextField = textField as? PrimerInputTextField else { return false }
            if !string.isEmpty {
                // Characters aren't in the allowed character set
                if let allowedCharacterSet = self.inputElement.type.allowedCharacterSet, string.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                    return false
                }
            }
            
            let currentText = primerCheckoutComponentsTextField._text ?? ""
            
            var newText = (currentText as NSString).replacingCharacters(in: range, with: string) as String
            if let deformattedText = self.inputElement.type.clearFormatting(value: newText) as? String {
                newText = deformattedText
            }
            
            if let maxAllowedLength = self.inputElement.type.maxAllowedLength {
                if newText.count > maxAllowedLength {
                    return false
                }
            }
            
//            DispatchQueue.global(qos: .userInitiated).async {
//            DispatchQueue.main.async {
            
            if self.inputElement.type == .cardNumber {
                if let cardNetwork = self.inputElement.type.detectType(for: newText) as? CardNetwork {
                    if self.detectedType == nil, cardNetwork != .unknown {
                        self.detectedType = cardNetwork
                        self.inputElementDelegate?.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    } else if self.detectedType != nil, cardNetwork == .unknown {
                        self.detectedType = nil
                        self.inputElementDelegate?.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    }
                } else {
                    if self.detectedType != nil {
                        self.detectedType = nil
                        self.inputElementDelegate?.inputElementDidDetectType?(self.inputElement, type: self.detectedType)
                    }
                }
            }
            
            if let cardNetwork = self.detectedType as? CardNetwork {
                if self.inputElement.type == .cardNumber,
                   let cardNetworkMaxAllowedLength = cardNetwork.validation?.lengths.max(),
                   newText.count > cardNetworkMaxAllowedLength {
                    return false
                }
                
            } else if let cardNetwork = primerCheckoutComponentsTextField.detectedValueType as? CardNetwork {
                if self.inputElement.type == .cvv {
                    if let cvvMaxAllowedLength = cardNetwork.validation?.code.length,
                       newText.count > cvvMaxAllowedLength {
                        return false
                    }
                }
            }
            
            let isValid = self.inputElement.type.validate(value: newText, detectedValueType: primerCheckoutComponentsTextField.detectedValueType)
            self.inputElementDelegate?.inputElementValueIsValid?(self.inputElement, isValid: isValid)
            
            let formattedText = self.inputElement.type.format(value: newText)
            textField.text = formattedText as? String
            
            return false
        }
    }
    
}

#endif

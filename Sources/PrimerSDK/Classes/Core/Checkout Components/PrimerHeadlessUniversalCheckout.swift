//
//  PrimerHeadlessUniversalCheckout.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/1/22.
//

#if canImport(UIKit)

import UIKit

public class PrimerHeadlessUniversalCheckout {
    
    public weak var delegate: PrimerHeadlessUniversalCheckoutDelegate?
    private(set) public var clientToken: String?
    public static let current = PrimerHeadlessUniversalCheckout()
    private let unsupportedPaymentMethodTypes: [PrimerPaymentMethodType] = [.adyenIDeal, .adyenDotPay, .adyenBlik, .goCardlessMandate, .primerTestKlarna, .primerTestSofort, .primerTestPayPal, .xfers]
    
    fileprivate init() {}
    
    public func start(withClientToken clientToken: String, settings: PrimerSettings? = nil, delegate: PrimerHeadlessUniversalCheckoutDelegate? = nil, completion: @escaping (_ paymentMethodTypes: [PrimerPaymentMethodType]?, _ err: Error?) -> Void) {
        Primer.shared.intent = .checkout
        
        if delegate != nil {
            PrimerHeadlessUniversalCheckout.current.delegate = delegate
        }
        
        if PrimerHeadlessUniversalCheckout.current.delegate == nil {
                    print("WARNING: PrimerHeadlessUniversalCheckout delegate has not been set, and you won't be able to receive the Payment Method Token data to create a payment.")
                }
                        
        if let settings = settings {
            DependencyContainer.register(settings as PrimerSettingsProtocol)
        }
        
        firstly {
            return ClientTokenService.storeClientToken(clientToken)
        }
        .then { () -> Promise<Void> in
            self.clientToken = clientToken
            let primerConfigurationService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            return primerConfigurationService.fetchConfig()
        }
        .done {
            let availablePaymentMethodsTypes = PrimerHeadlessUniversalCheckout.current.listAvailablePaymentMethodsTypes()
            if (availablePaymentMethodsTypes ?? []).isEmpty {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
            guard let clientToken = AppState.current.clientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token is nil"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let decodedClientToken = clientToken.jwtTokenPayload else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)", "reason": "Client token cannot be decoded"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            do {
                try decodedClientToken.validate()
            } catch {
                seal.reject(error)
            }
            
            guard let apiConfiguration = AppState.current.apiConfiguration else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            guard let paymentMethods = apiConfiguration.paymentMethods, !paymentMethods.isEmpty else {
                let err = PrimerError.misconfiguredPaymentMethods(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                seal.reject(err)
                return
            }
            
            seal.fulfill()
        }
    }
    
    internal func validateSession() -> Promise<Void> {
        return Promise { seal in
            if AppState.current.clientToken == nil, let clientToken = PrimerHeadlessUniversalCheckout.current.clientToken {
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
        return PrimerAPIConfiguration.paymentMethodConfigs?.compactMap({ $0.type }).filter({ !unsupportedPaymentMethodTypes.contains($0) })
    }
    
    public func listRequiredInputElementTypes(for paymentMethodType: PrimerPaymentMethodType) -> [PrimerInputElementType]? {
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
        case .adyenPayshop:
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
        case .coinbase:
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
            var requiredFields: [PrimerInputElementType] = [.cardNumber, .expiryDate, .cvv]
            if let checkoutModule = AppState.current.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first,
               let options = checkoutModule.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions {
                if options.cardHolderName == true {
                    requiredFields.append(.cardholderName)
                }
            }
            return requiredFields
        case .payPal:
            return []
        case .primerTestPayPal,
                .primerTestKlarna,
                .primerTestSofort:
            return []
        case .xfers:
            return []
        case .opennode:
            return []
        case .rapydGCash:
            return []
        case .twoCtwoP:
            return []
        case .rapydGrabPay:
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
    
    public static func getAsset(for paymentMethodType: PrimerPaymentMethodType, assetType: PrimerAsset.ImageType) -> UIImage? {
        return PrimerAsset.getAsset(for: paymentMethodType, assetType: assetType)
    }
    
    public static func getAsset(for cardNetwork: CardNetwork, assetType: PrimerAsset.ImageType) -> UIImage? {
        return PrimerAsset.getAsset(for: cardNetwork, assetType: assetType)
    }
    
    public func showPaymentMethod(_ paymentMethod: PrimerPaymentMethodType, completion: ((_ viewController: UIViewController) -> Void)? = nil) {
        DispatchQueue.main.async {
            let appState: AppStateProtocol = DependencyContainer.resolve()
            guard let clientToken = appState.clientToken else {
                print("WARNING: Make sure you have called 'start(withClientToken:settings:delegate:completion:' with a valid client token prior to showing a payment method.")
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
            }
            
            if self.unsupportedPaymentMethodTypes.contains(paymentMethod) || paymentMethod == .paymentCard {
                let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: paymentMethod, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
            }
            
            PrimerSettings.current.uiOptions.isInitScreenEnabled = false
            PrimerSettings.current.uiOptions.isSuccessScreenEnabled = false
            PrimerSettings.current.uiOptions.isErrorScreenEnabled = false
            
            switch paymentMethod {
            case .goCardlessMandate,
                    .paymentCard,
                    .other:
                let err = PrimerError.missingCustomUI(paymentMethod: paymentMethod, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                return
            case .applePay:
                if PrimerSettings.current.paymentMethodOptions.applePayOptions == nil {
                    let err = PrimerError.invalidValue(key: "settings.paymentMethodOptions.applePayOptions", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                    return
                }
                
            case .payPal:
                if PrimerSettings.current.paymentMethodOptions.urlScheme == nil {
                    let err = PrimerError.invalidUrlScheme(urlScheme: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutDidFail?(withError: err)
                    return
                }
            default:
                break
            }
            
            PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPreparationDidStart?(for: paymentMethod.rawValue)
            Primer.shared.showPaymentMethod(paymentMethod, withIntent: .checkout, andClientToken: clientToken)
        }
    }
}

public struct PrimerAsset {
    
    public static func getAsset(for brand: PrimerAsset.Brand, assetType: PrimerAsset.ImageType) -> UIImage? {
        return brand.getImage(assetType: assetType)
    }
    
    public static func getAsset(for paymentMethodType: PrimerPaymentMethodType, assetType: PrimerAsset.ImageType) -> UIImage? {
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
        case .adyenPayshop:
            brand = .payshop
        case .adyenPayTrail:
            brand = .payTrail
        case .adyenSofort,
                .buckarooSofort,
                .primerTestSofort:
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
        case .coinbase:
            brand = .coinBase
        case .goCardlessMandate:
            brand = .goCardless
        case .googlePay:
            brand = .googlePay
        case .hoolah:
            brand = .hoolah
        case .klarna,
                .primerTestKlarna:
            brand = .klarna
        case .payNLPayconiq:
            brand = .payconiq
        case .paymentCard:
            return nil
        case .payPal,
                .primerTestPayPal:
            brand = .payPal
        case .twoCtwoP:
            brand = .twoCtwoP
        case .rapydGCash:
            brand = .gCash
        case .xfers:
            brand = .xfers
        case .rapydGrabPay:
            brand = .grabPay
        case .opennode:
            brand = .opennode
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
        case p24, payNL = "pay-nl", payconiq, payNow = "paynow", payPal = "paypal", primer, printful, payTrail = "paytrail", payshop
        case ravelin, riskified
        case seon, sepa, sift, signifyd, sofort, stitch, stripe, swish
        case tableau, taxjar, telserv, tink, trilo, trueLayer = "truelayer", trueMoney = "truemoney", trustly, twillio, twint
        case vipps, visa, volt, voucherify, vyne
        case wordline, worldPay = "worldpay"
        case twoCtwoP = "2c2p"
        case xfers
        case opennode
        
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

//
//  TokenizationResponse.swift
//  PrimerSDK
//
//  Created by Evangelos on 2/9/22.
//



import Foundation

extension Response.Body {
    
    public class Tokenization: NSObject, Codable {
        
        public var analyticsId: String?
        public var id: String?
        internal var isAlreadyVaulted: Bool?
        public var isVaulted: Bool?
        public var paymentMethodType: String?
        public var paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData?
        public var paymentInstrumentType: PaymentInstrumentType
        public var threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
        public var token: String?
        public var tokenType: TokenType?
        public var vaultData: Response.Body.Tokenization.VaultData?
        
        init(
            analyticsId: String?,
            id: String?,
            isVaulted: Bool?,
            isAlreadyVaulted: Bool?,
            paymentInstrumentType: PaymentInstrumentType,
            paymentMethodType: String?,
            paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData?,
            threeDSecureAuthentication: ThreeDS.AuthenticationDetails?,
            token: String?,
            tokenType: TokenType?,
            vaultData: Response.Body.Tokenization.VaultData?
        ) {
            self.analyticsId = analyticsId
            self.id = id
            self.isVaulted = isVaulted
            self.isAlreadyVaulted = isAlreadyVaulted
            self.paymentMethodType = paymentMethodType
            self.paymentInstrumentType = paymentInstrumentType
            self.paymentInstrumentData = paymentInstrumentData
            self.threeDSecureAuthentication = threeDSecureAuthentication
            self.token = token
            self.tokenType = tokenType
            self.vaultData = vaultData
        }
    }
}

// Should be removed
extension Response.Body.Tokenization {
    
    public var icon: ImageName {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let network = self.paymentInstrumentData?.network else { return .genericCard }
            switch network {
            case "Visa": return .visa
            case "Mastercard": return .masterCard
            default: return .genericCard
            }
        case .payPalOrder: return .paypal2
        case .payPalBillingAgreement: return .paypal2
        case .goCardlessMandate: return .bank
        case .klarnaCustomerToken: return .klarna
        default: return .creditCard
        }
    }
    
    var cardButtonViewModel: CardButtonViewModel? {
        switch self.paymentInstrumentType {
        case .paymentCard:
            guard let ntwrk = self.paymentInstrumentData?.network else { return nil }
            guard let last4 = self.paymentInstrumentData?.last4Digits else { return nil }
            guard let expMonth = self.paymentInstrumentData?.expirationMonth else { return nil }
            guard let expYear = self.paymentInstrumentData?.expirationYear else { return nil }
            return CardButtonViewModel(
                network: ntwrk,
                cardholder: self.paymentInstrumentData?.cardholderName ?? "",
                last4: "•••• \(last4)",
                expiry: Strings.PrimerCardFormView.savedCardTitle + " \(expMonth) / \(expYear.suffix(2))",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType)
        case .payPalBillingAgreement:
            guard let cardholder = self.paymentInstrumentData?.externalPayerInfo?.email else { return nil }
            return CardButtonViewModel(network: "PayPal", cardholder: cardholder, last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
        case .goCardlessMandate:
            return CardButtonViewModel(network: "Bank account", cardholder: "", last4: "", expiry: "", imageName: self.icon, paymentMethodType: self.paymentInstrumentType)
        case .klarnaCustomerToken:
            return CardButtonViewModel(
                network: paymentInstrumentData?.sessionData?.billingAddress?.email ?? "Klarna Customer Token",
                cardholder: "",
                last4: "",
                expiry: "",
                imageName: self.icon,
                paymentMethodType: self.paymentInstrumentType)
        case .apayaToken:
            if let apayaViewModel = Apaya.ViewModel(paymentMethod: self) {
                return CardButtonViewModel(
                    network: "[\(apayaViewModel.carrier.name)] \(apayaViewModel.hashedIdentifier ?? "")",
                    cardholder: "Apaya",
                    last4: "",
                    expiry: "",
                    imageName: self.icon,
                    paymentMethodType: self.paymentInstrumentType)
            } else {
                return nil
            }
            
        default:
            return nil
        }
    }
}

extension Response.Body.Tokenization {

    public struct PaymentInstrumentData: Codable {
        
        public let paypalBillingAgreementId: String?
        public let first6Digits: String?
        public let last4Digits: String?
        public let expirationMonth: String?
        public let expirationYear: String?
        public let cardholderName: String?
        public let network: String?
        public let isNetworkTokenized: Bool?
        public let klarnaCustomerToken: String?
        public let sessionData: Response.Body.Klarna.SessionData?
        public let externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo?
        public let shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress?
        public let binData: BinData?
        public let threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
        public let gocardlessMandateId: String?
        public let authorizationToken: String?
        // APAYA
        public let hashedIdentifier: String?
        public let mnc: Int?
        public let mcc: Int?
        public let mx: String?
        public let currencyCode: Currency?
        public let productId: String?
        
        public let paymentMethodConfigId: String?
        public let paymentMethodType: String?
        public let sessionInfo: SessionInfo?
        
        public struct SessionInfo: Codable {
            public let locale: String?
            public let platform: String?
            public let redirectionUrl: String?
        }
        
        // TODO: (NOL) add something for nol?
//        public let appId: String?
    }
}

extension Response.Body.Tokenization {
    
    public struct VaultData: Codable {
        public var customerId: String
    }
}



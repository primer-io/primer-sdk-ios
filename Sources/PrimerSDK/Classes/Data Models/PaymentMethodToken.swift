#if canImport(UIKit)

import Foundation

struct GetVaultedPaymentMethodsResponse: Decodable {
    var data: [PrimerPaymentMethodTokenData]
}

/**
 Each **PaymentMethodToken** represents a payment method added on Primer and carries the necessary information
 for identification (e.g. type), as well as further information to be used if needed.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public class PaymentMethodToken: NSObject, Codable {
    
    public var analyticsId: String?
    public var id: String?
    public var isVaulted: Bool?
    private var isAlreadyVaulted: Bool?
    public var paymentInstrumentType: PaymentInstrumentType
    public var paymentMethodType: String?
    public var paymentInstrumentData: PaymentInstrumentData?
    public var threeDSecureAuthentication: ThreeDS.AuthenticationDetails?
    public var token: String?
    public var tokenType: TokenType?
    public var vaultData: VaultData?

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
}

internal extension PaymentMethodToken {
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

struct CardButtonViewModel {
    let network, cardholder, last4, expiry: String
    let imageName: ImageName
    let paymentMethodType: PaymentInstrumentType
    var surCharge: Int? {
        guard let options = AppState.current.apiConfiguration?.clientSession?.paymentMethod?.options else { return nil }
        guard let paymentCardOption = options.filter({ $0["type"] as? String == PrimerPaymentMethodType.paymentCard.rawValue }).first else { return nil }
        guard let networks = paymentCardOption["networks"] as? [[String: Any]] else { return nil }
        guard let tmpNetwork = networks.filter({ ($0["type"] as? String)?.lowercased() == network.lowercased() }).first else { return nil }
        return tmpNetwork["surcharge"] as? Int
    }
}

#endif

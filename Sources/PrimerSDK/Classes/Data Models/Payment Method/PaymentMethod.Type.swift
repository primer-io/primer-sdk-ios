//
//  PaymentMethodType.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/4/22.
//

import Foundation

extension PaymentMethod {
    
    public enum PaymentMethodType: Codable, Equatable {
        case adyenAlipay
        case adyenBlik
        case adyenDotPay
        case adyenGiropay
        case adyenIDeal
        case adyenMobilePay
        case adyenSofort
        case adyenTrustly
        case adyenTwint
        case adyenVipps
        case apaya
        case applePay
        case atome
        case buckarooBancontact
        case buckarooEps
        case buckarooGiropay
        case buckarooIdeal
        case buckarooSofort
        case goCardlessMandate
        case googlePay
        case hoolah
        case klarna
        case mollieBankcontact
        case mollieIdeal
        case payNLBancontact
        case payNLGiropay
        case payNLIdeal
        case payNLPayconiq
        case paymentCard
        case payPal
        case xfers
        case other(rawValue: String)
        
        // swiftlint:disable cyclomatic_complexity
        public init(rawValue: String) {
            switch rawValue {
            case "ADYEN_ALIPAY":
                self = .adyenAlipay
            case "ADYEN_BLIK":
                self = .adyenBlik
            case "ADYEN_DOTPAY":
                self = .adyenDotPay
            case "ADYEN_GIROPAY":
                self = .adyenGiropay
            case "ADYEN_IDEAL":
                self = .adyenIDeal
            case "ADYEN_MOBILEPAY":
                self = .adyenMobilePay
            case "ADYEN_SOFORT":
                self = .adyenSofort
            case "ADYEN_TRUSTLY":
                self = .adyenTrustly
            case "ADYEN_TWINT":
                self = .adyenTwint
            case "ADYEN_VIPPS":
                self = .adyenVipps
            case "APAYA":
                self = .apaya
            case "APPLE_PAY":
                self = .applePay
            case "ATOME":
                self = .atome
            case "BUCKAROO_BANCONTACT":
                self = .buckarooBancontact
            case "BUCKAROO_EPS":
                self = .buckarooEps
            case "BUCKAROO_GIROPAY":
                self = .buckarooGiropay
            case "BUCKAROO_IDEAL":
                self = .buckarooIdeal
            case "BUCKAROO_SOFORT":
                self = .buckarooSofort
            case "GOCARDLESS":
                self = .goCardlessMandate
            case "GOOGLE_PAY":
                self = .googlePay
            case "HOOLAH":
                self = .hoolah
            case "KLARNA":
                self = .klarna
            case "MOLLIE_BANCONTACT":
                self = .mollieBankcontact
            case "MOLLIE_IDEAL":
                self = .mollieIdeal
            case "PAY_NL_BANCONTACT":
                self = .payNLBancontact
            case "PAY_NL_GIROPAY":
                self = .payNLGiropay
            case "PAY_NL_IDEAL":
                self = .payNLIdeal
            case "PAY_NL_PAYCONIQ":
                self = .payNLPayconiq
            case "PAYMENT_CARD":
                self = .paymentCard
            case "PAYPAL":
                self = .payPal
            case "XFERS_PAYNOW":
                self = .xfers
            default:
                self = .other(rawValue: rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .adyenAlipay:
                return "ADYEN_ALIPAY"
            case .adyenBlik:
                return "ADYEN_BLIK"
            case .adyenDotPay:
                return "ADYEN_DOTPAY"
            case .adyenGiropay:
                return "ADYEN_GIROPAY"
            case .adyenIDeal:
                return "ADYEN_IDEAL"
            case .adyenMobilePay:
                return "ADYEN_MOBILEPAY"
            case .adyenSofort:
                return "ADYEN_SOFORT"
            case .adyenTrustly:
                return "ADYEN_TRUSTLY"
            case .adyenTwint:
                return "ADYEN_TWINT"
            case .adyenVipps:
                return "ADYEN_VIPPS"
            case .apaya:
                return "APAYA"
            case .applePay:
                return "APPLE_PAY"
            case .atome:
                return "ATOME"
            case .buckarooBancontact:
                return "BUCKAROO_BANCONTACT"
            case .buckarooEps:
                return "BUCKAROO_EPS"
            case .buckarooGiropay:
                return "BUCKAROO_GIROPAY"
            case .buckarooIdeal:
                return "BUCKAROO_IDEAL"
            case .buckarooSofort:
                return "BUCKAROO_SOFORT"
            case .goCardlessMandate:
                return "GOCARDLESS"
            case .googlePay:
                return "GOOGLE_PAY"
            case .hoolah:
                return "HOOLAH"
            case .klarna:
                return "KLARNA"
            case .mollieBankcontact:
                return "MOLLIE_BANCONTACT"
            case .mollieIdeal:
                return "MOLLIE_IDEAL"
            case .payNLBancontact:
                return "PAY_NL_BANCONTACT"
            case .payNLGiropay:
                return "PAY_NL_GIROPAY"
            case .payNLIdeal:
                return "PAY_NL_IDEAL"
            case .payNLPayconiq:
                return "PAY_NL_PAYCONIQ"
            case .paymentCard:
                return "PAYMENT_CARD"
            case .payPal:
                return "PAYPAL"
            case .xfers:
                return "XFERS_PAYNOW"
            case .other(let rawValue):
                return rawValue
            }
        }
        
        var isEnabled: Bool {
            switch self {
            case .adyenAlipay,
                    .adyenBlik,
                    .adyenDotPay,
                    .adyenGiropay,
                    .adyenIDeal,
                    .adyenMobilePay,
                    .adyenSofort,
                    .adyenTrustly,
                    .adyenTwint,
                    .adyenVipps,
                    .applePay,
                    .atome,
                    .buckarooBancontact,
                    .buckarooEps,
                    .buckarooGiropay,
                    .buckarooIdeal,
                    .buckarooSofort,
                    .hoolah,
                    .mollieBankcontact,
                    .mollieIdeal,
                    .payNLBancontact,
                    .payNLGiropay,
                    .payNLIdeal,
                    .payNLPayconiq,
                    .xfers:
                guard let flow = Primer.shared.flow else { return false }
                return !flow.internalSessionFlow.vaulted
                
            case .apaya,
                    .klarna:
                guard let flow = Primer.shared.flow else { return false }
                return flow.internalSessionFlow.vaulted
                
            case .goCardlessMandate,
                    .googlePay:
                return false
                
            case .paymentCard,
                    .payPal:
                return true
            
            case .other:
                return true
            }
        }
        // swiftlint:enable cyclomatic_complexity
        
        private enum CodingKeys: String, CodingKey {
            case adyenAlipay
            case adyenBlik
            case adyenDotPay
            case adyenGiropay
            case adyenIDeal
            case adyenMobilePay
            case adyenSofort
            case adyenTrustly
            case adyenTwint
            case adyenVipps
            case apaya
            case applePay
            case atome
            case buckarooBancontact
            case buckarooEps
            case buckarooGiropay
            case buckarooIdeal
            case buckarooSofort
            case goCardlessMandate
            case googlePay
            case hoolah
            case klarna
            case mbWay
            case mollieBankcontact
            case mollieIdeal
            case payNLBancontact
            case payNLGiropay
            case payNLIdeal
            case payNLPayconiq
            case paymentCard
            case payPal
            case xfers
            case other
        }
        
        public init(from decoder: Decoder) throws {
            let rawValue: String = try decoder.singleValueContainer().decode(String.self)
            self = PaymentMethod.PaymentMethodType(rawValue: rawValue)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.rawValue, forKey: CodingKeys(rawValue: "type")!)
        }
        
        var logo: UIImage? {
            return nil
        }
        
        var icon: UIImage? {
            return nil
        }
    }
    
}

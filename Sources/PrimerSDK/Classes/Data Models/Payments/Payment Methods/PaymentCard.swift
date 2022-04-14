//
//  PaymentCard.swift
//  PrimerSDK
//
//  Created by Evangelos on 14/4/22.
//


#if canImport(UIKit)

import Foundation
import PassKit
import UIKit

extension PaymentMethod {
    
    // MARK: - Payment Card ✅
    public class PaymentCard {
        public class Configuration {
            struct Options: PaymentMethodConfigurationOptions {
                let threeDSecureEnabled: Bool
                let threeDSecureToken: String?
                let threeDSecureInitUrl: String?
                let threeDSecureProvider: String
                let processorConfigId: String?
            }
        }
        
        public class Tokenization {
            struct InstrumentRequestParameters: PaymentMethodTokenizationInstrumentRequestParameters {
                let number: String
                let cvv: String
                let expirationMonth: String
                let expirationYear: String
                let cardholderName: String?
            }
            
            public struct InstrumentResponseData: PaymentMethodTokenizationInstrumentResponseData {
                public let first6Digits: String?
                public let last4Digits: String
                public let expirationMonth: String
                public let expirationYear: String
                public let cardholderName: String?
                public let network: String
                public let isNetworkTokenized: Bool
                public let binData: PaymentMethod.PaymentCard.BinData?
            }
        }
        
        public struct BinData: Codable {
            public var accountFundingType: String?
            public var accountNumberType: String?
            public var network: String?
            public var issuerCountryCode: String?
            public var issuerCurrencyCode: String?
            public var issuerName: String?
            public var prepaidReloadableIndicator: String?
            public var productCode: String?
            public var productName: String?
            public var productUsageType: String?
            public var regionalRestriction: String?
        }
        
        struct ButtonViewModel {
            let network, cardholder, last4, expiry: String
            let imageName: ImageName
            let paymentMethodType: PaymentMethod.Tokenization.Response.InstrumentType
            var surCharge: Int? {
                let state: AppStateProtocol = DependencyContainer.resolve()
                guard let options = state.primerConfiguration?.clientSession?.paymentMethod?.options else { return nil }
                guard let paymentCardOption = options.filter({ $0["type"] as? String == "PAYMENT_CARD" }).first else { return nil }
                guard let networks = paymentCardOption["networks"] as? [[String: Any]] else { return nil }
                guard let tmpNetwork = networks.filter({ ($0["type"] as? String)?.lowercased() == network.lowercased() }).first else { return nil }
                return tmpNetwork["surcharge"] as? Int
            }
        }
        
        struct NetworkValidation {
            var niceType: String
            var patterns: [[Int]]
            var gaps: [Int]
            var lengths: [Int]
            var code: NetworkCode
        }

        struct NetworkCode {
            var name: String
            var length: Int
        }
        
        public enum Network: String, CaseIterable {
            case amex
            case bancontact
            case diners
            case discover
            case elo
            case hiper
            case hipercard
            case jcb
            case maestro
            case masterCard = "mastercard"
            case mir
            case visa
            case unionpay
            case unknown
                        
            static var iOSSupportedPKPaymentNetworks: [PKPaymentNetwork] {
                var supportedNetworks: [PKPaymentNetwork] = [
                    .amex,
                    .chinaUnionPay,
                    .discover,
                    .interac,
                    .masterCard,
                    .privateLabel,
                    .visa
                ]
                
                if #available(iOS 11.2, *) {
        //            @available(iOS 11.2, *)
                    supportedNetworks.append(.cartesBancaires)
                } else if #available(iOS 11.0, *) {
        //            @available(iOS, introduced: 11.0, deprecated: 11.2, message: "Use PKPaymentNetworkCartesBancaires instead.")
                    supportedNetworks.append(.carteBancaires)
                } else if #available(iOS 10.3, *) {
        //            @available(iOS, introduced: 10.3, deprecated: 11.0, message: "Use PKPaymentNetworkCartesBancaires instead.")
                    supportedNetworks.append(.carteBancaire)
                }

                if #available(iOS 12.0, *) {
        //            @available(iOS 12.0, *)
                    supportedNetworks.append(.eftpos)
                    supportedNetworks.append(.electron)
                    supportedNetworks.append(.maestro)
                    supportedNetworks.append(.vPay)
                }

                if #available(iOS 12.1.1, *) {
        //            @available(iOS 12.1.1, *)
                    supportedNetworks.append(.elo)
                    supportedNetworks.append(.mada)
                }
                
                if #available(iOS 10.3.1, *) {
        //            @available(iOS 10.3, *)
                    supportedNetworks.append(.idCredit)
                }
                
                if #available(iOS 10.1, *) {
        //            @available(iOS 10.1, *)
                    supportedNetworks.append(.JCB)
                    supportedNetworks.append(.suica)
                }
                
                if #available(iOS 10.3, *) {
        //            @available(iOS 10.3, *)
                    supportedNetworks.append(.quicPay)
                }
                
                if #available(iOS 14.0, *) {
        //            @available(iOS 14.0, *)
        //            supportedNetworks.append(.barcode)
                    supportedNetworks.append(.girocard)
                }
                
                return supportedNetworks
            }
            
            var validation: NetworkValidation? {
                switch self {
                case .amex:
                    return NetworkValidation(
                        niceType: "American Express",
                        patterns: [[34], [37]],
                        gaps: [4, 10],
                        lengths: [15],
                        code: NetworkCode(
                            name: "CID",
                            length: 4))
                    
                case .bancontact:
                    return nil
                    
                case .diners:
                    return NetworkValidation(
                        niceType: "Diners",
                        patterns: [[300, 305], [36], [38], [39]],
                        gaps: [4, 10],
                        lengths: [14, 16, 19],
                        code: NetworkCode(
                            name: "CVV",
                            length: 3))
                    
                case .discover:
                    return NetworkValidation(
                        niceType: "Discover",
                        patterns: [[6011], [644, 649], [65]],
                        gaps: [4, 8, 12],
                        lengths: [16, 19],
                        code: NetworkCode(
                            name: "CID",
                            length: 3))
                    
                case .elo:
                    return NetworkValidation(
                        niceType: "Elo",
                        patterns: [
                            [401178],
                            [401179],
                            [438935],
                            [457631],
                            [457632],
                            [431274],
                            [451416],
                            [457393],
                            [504175],
                            [506699, 506778],
                            [509000, 509999],
                            [627780],
                            [636297],
                            [636368],
                            [650031, 650033],
                            [650035, 650051],
                            [650405, 650439],
                            [650485, 650538],
                            [650541, 650598],
                            [650700, 650718],
                            [650720, 650727],
                            [650901, 650978],
                            [651652, 651679],
                            [655000, 655019],
                            [655021, 655058],
                        ],
                        gaps: [4, 8, 12],
                        lengths: [16],
                        code: NetworkCode(
                            name: "CVE",
                            length: 3))
                    
                case .hiper:
                    return NetworkValidation(
                        niceType: "Hiper",
                        patterns: [[637095], [63737423], [63743358], [637568], [637599], [637609], [637612]],
                        gaps: [4, 8, 12],
                        lengths: [16],
                        code: NetworkCode(
                            name: "CVC",
                            length: 3))
                    
                case .hipercard:
                    return NetworkValidation(
                        niceType: "Hiper",
                        patterns: [[606282]],
                        gaps: [4, 8, 12],
                        lengths: [16],
                        code: NetworkCode(
                            name: "CVC",
                            length: 3))
                    
                case .jcb:
                    return NetworkValidation(
                        niceType: "JCB",
                        patterns: [[2131], [1800], [3528, 3589]],
                        gaps: [4, 8, 12],
                        lengths: [16, 17, 18, 19],
                        code: NetworkCode(
                            name: "CVV",
                            length: 3))
                    
                case .masterCard:
                    return NetworkValidation(
                        niceType: "Mastercard",
                        patterns: [[51, 55], [2221, 2229], [223, 229], [23, 26], [270, 271], [2720]],
                        gaps: [4, 10],
                        lengths: [16],
                        code: NetworkCode(
                            name: "CVC",
                            length: 3))
                    
                case .maestro:
                    return NetworkValidation(
                        niceType: "Maestro",
                        patterns: [
                            [493698],
                            [500000, 504174],
                            [504176, 506698],
                            [506779, 508999],
                            [56, 59],
                            [63],
                            [67],
                            [6],
                          ],
                        gaps: [4, 8, 12],
                        lengths: [16, 17, 18, 19],
                        code: NetworkCode(
                            name: "CVC",
                            length: 3))
                    
                case .mir:
                    return NetworkValidation(
                        niceType: "Mir",
                        patterns: [[2200, 2204]],
                        gaps: [4, 8, 12],
                        lengths: [16, 17, 18, 19],
                        code: NetworkCode(
                            name: "CVP2",
                            length: 3))
                    
                case .visa:
                    return NetworkValidation(
                        niceType: "Visa",
                        patterns: [[4]],
                        gaps: [4, 8, 12],
                        lengths: [16, 18, 19],
                        code: NetworkCode(
                            name: "CVV",
                            length: 3))

                case .unionpay:
                    return NetworkValidation(
                        niceType: "UnionPay",
                        patterns: [
                      [620],
                      [624, 626],
                      [62100, 62182],
                      [62184, 62187],
                      [62185, 62197],
                      [62200, 62205],
                      [622010, 622999],
                      [622018],
                      [622019, 622999],
                      [62207, 62209],
                      [622126, 622925],
                      [623, 626],
                      [6270],
                      [6272],
                      [6276],
                      [627700, 627779],
                      [627781, 627799],
                      [6282, 6289],
                      [6291],
                      [6292],
                      [810],
                      [8110, 8131],
                      [8132, 8151],
                      [8152, 8163],
                      [8164, 8171],
                    ],
                        gaps: [4, 8, 12],
                        lengths: [14, 15, 16, 17, 18, 19],
                        code: NetworkCode(
                            name: "CVN",
                            length: 3))
                case .unknown:
                    return nil
                }
            }
            
            public var icon: UIImage? {
                switch self {
                case .amex:
                    return UIImage(named: "amex", in: Bundle.primerResources, compatibleWith: nil)
                case .bancontact:
                    return UIImage(named: "bancontact-icon", in: Bundle.primerResources, compatibleWith: nil)
                case .diners:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                case .discover:
                    return UIImage(named: "discover", in: Bundle.primerResources, compatibleWith: nil)
                case .elo:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                case .hiper:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                case .hipercard:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                case .jcb:
                    return UIImage(named: "jcb-icon", in: Bundle.primerResources, compatibleWith: nil)
                case .maestro:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                case .mir:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                case .masterCard:
                    return UIImage(named: "masterCard", in: Bundle.primerResources, compatibleWith: nil)
                case .unionpay:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                case .visa:
                    return UIImage(named: "visa", in: Bundle.primerResources, compatibleWith: nil)
                case .unknown:
                    return UIImage(named: "genericCard", in: Bundle.primerResources, compatibleWith: nil)
                }
            }
            
            var directoryServerId: String? {
                switch self {
                case .visa:
                    return "A000000003"
                case .masterCard:
                    return "A000000004"
                case .amex:
                    return "A000000025"
                case .jcb:
                    return "A000000065"
                case .diners:
                    return "A000000152"
                case .unionpay:
                    return "A000000333"
                default:
                    if let decodedClientToken = ClientTokenService.decodedClientToken,
                       let env = decodedClientToken.env {
                        if env.uppercased() == "PRODUCTION" {
                            return nil
                        } else {
                            return "A999999999"
                        }
                    } else {
                        return nil
                    }
                }
            }
            
            var surcharge: Int? {
                let state: AppStateProtocol = DependencyContainer.resolve()
                guard let options = state.primerConfiguration?.clientSession?.paymentMethod?.options, !options.isEmpty else { return nil }
                
                for paymentMethodOption in options {
                    guard let type = paymentMethodOption["type"] as? String, type == "PAYMENT_CARD" else { continue }
                    guard let networks = paymentMethodOption["networks"] as? [[String: Any]] else { continue }
                    guard let tmpNetwork = networks.filter({ $0["type"] as? String == self.rawValue.uppercased() }).first else { continue }
                    guard let surcharge = tmpNetwork["surcharge"] as? Int else { continue }
                    return surcharge
                }
                
                return nil
            }
            
            static func cardNumber(_ cardnumber: String, matchesPatterns patterns: [[Int]]) -> Bool {
                for pattern in patterns {
                    if pattern.count == 1 || pattern.count == 2 {
                        let min = pattern.first!
                        let max = pattern.count == 2 ? pattern[1] : min
                        
                        for num in min...max {
                            let numStr = String(num)
                            if cardnumber.withoutNonNumericCharacters.hasPrefix(numStr) {
                                return true
                            }
                        }
                    } else {
                        log(logLevel: .warning, message: "Card network patterns array must contain one or two Ints")
                    }
                }
                
                return false
            }
            
            public init(cardNumber: String) {
                self = .unknown
                
                for cardNetwork in PaymentMethod.PaymentCard.Network.allCases {
                    if let patterns = cardNetwork.validation?.patterns,
                       PaymentMethod.PaymentCard.Network.cardNumber(cardNumber.withoutNonNumericCharacters, matchesPatterns: patterns),
                       cardNetwork != .unknown {
                        self = cardNetwork
                        break
                    }
                }
            }
            
            public init(cardNetworkStr: String) {
                self = .unknown
                
                if let cardNetwork = PaymentMethod.PaymentCard.Network(rawValue: cardNetworkStr.lowercased()) {
                    self = cardNetwork
                }
            }
            
        }
    }
    
}

#endif

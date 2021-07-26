//
//  CardNetwork.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 29/6/21.
//

import Foundation

struct CardNetworkValidation {
    var niceType: String
    var patterns: [[Int]]
    var gaps: [Int]
    var lengths: [Int]
    var code: CardNetworkCode
}

struct CardNetworkCode {
    var name: String
    var length: Int
}

public enum CardNetwork: String, CaseIterable {
    
    case amex
    case bancontact
    case diners
    case discover
    case elo
    case hiper
    case hipercard
    case jcb
    case maestro
    case masterCard
    case mir
    case visa
    case unionpay
    case unknown
    
    var validation: CardNetworkValidation? {
        switch self {
        case .amex:
            return CardNetworkValidation(
                niceType: "American Express",
                patterns: [[34], [37]],
                gaps: [4, 10],
                lengths: [15],
                code: CardNetworkCode(
                    name: "CID",
                    length: 4))
            
        case .bancontact:
            return nil
            
        case .diners:
            return CardNetworkValidation(
                niceType: "Diners",
                patterns: [[300, 305], [36], [38], [39]],
                gaps: [4, 10],
                lengths: [14, 16, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))
            
        case .discover:
            return CardNetworkValidation(
                niceType: "Discover",
                patterns: [[6011], [644, 649], [65]],
                gaps: [4, 8, 12],
                lengths: [16, 19],
                code: CardNetworkCode(
                    name: "CID",
                    length: 3))
            
        case .elo:
            return CardNetworkValidation(
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
                code: CardNetworkCode(
                    name: "CVE",
                    length: 3))
            
        case .hiper:
            return CardNetworkValidation(
                niceType: "Hiper",
                patterns: [[637095], [63737423], [63743358], [637568], [637599], [637609], [637612]],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))
            
        case .hipercard:
            return CardNetworkValidation(
                niceType: "Hiper",
                patterns: [[606282]],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))
            
        case .jcb:
            return CardNetworkValidation(
                niceType: "JCB",
                patterns: [[2131], [1800], [3528, 3589]],
                gaps: [4, 8, 12],
                lengths: [16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))
            
        case .masterCard:
            return CardNetworkValidation(
                niceType: "Mastercard",
                patterns: [[51, 55], [2221, 2229], [223, 229], [23, 26], [270, 271], [2720]],
                gaps: [4, 10],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))
            
        case .maestro:
            return CardNetworkValidation(
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
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))
            
        case .mir:
            return CardNetworkValidation(
                niceType: "Mir",
                patterns: [[2200, 2204]],
                gaps: [4, 8, 12],
                lengths: [16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVP2",
                    length: 3))
            
        case .visa:
            return CardNetworkValidation(
                niceType: "Visa",
                patterns: [[4]],
                gaps: [4, 8, 12],
                lengths: [16, 18, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))

        case .unionpay:
            return CardNetworkValidation(
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
                code: CardNetworkCode(
                    name: "CVN",
                    length: 3))
        case .unknown:
            return nil
        }
    }
    
    public var icon: UIImage? {
        return nil
    }
    
    static func cardNumber(_ cardnumber: String, matchesPatterns patterns: [[Int]]) -> Bool {
        for pattern in patterns {
            if pattern.count == 1 {
                let patternStr = String(pattern.first!)
                if cardnumber.withoutNonNumericCharacters.hasPrefix(patternStr) {
                    return true
                }
                
            } else if pattern.count == 2 {
                let min = pattern.first!
                let max = pattern[1]
                
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
        
        for cardNetwork in CardNetwork.allCases {
            if let patterns = cardNetwork.validation?.patterns,
               CardNetwork.cardNumber(cardNumber.withoutNonNumericCharacters, matchesPatterns: patterns) {
                self = cardNetwork
                break
            }
        }
    }
    
}

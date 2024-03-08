//
//  CardNetworkParser.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 07/03/2024.
//

import Foundation

class CardNetworkParser {

    let mapping: [ClosedRange<Int>: CardNetwork]

    let index: [ClosedRange<Int>]

    static let shared: CardNetworkParser = .init()

    private init() {
        var mapping: [ClosedRange<Int>: CardNetwork] = [:]
        CardNetwork.allCases.forEach { network in
            guard let validation = network.validation else {
                return
            }
            let ranges = validation.patterns.compactMap { bounds -> ClosedRange<Int>? in
                if bounds.count == 1 {
                    return bounds[0]...bounds[0]
                } else if bounds.count == 2 {
                    return bounds[0]...bounds[1]
                } else {
                    PrimerLogging.shared.logger.warn(message: """
Encountered a card network validation range with \(bounds.count) bounds. 
Ensure ranges have exactly one or exactly two bounds.
""")
                    return nil
                }
            }
            ranges.forEach { range in
                mapping[range] = network
            }
        }
        self.mapping = mapping
        self.index = mapping.keys.sorted(by: { range1, range2 in
            let max1 = max(range1.lowerBound, range1.upperBound)
            let max2 = max(range2.lowerBound, range2.upperBound)
            return max1 > max2
        })
        print("TEST")
    }

    func cardNetwork(from cardNumberString: String) -> CardNetwork? {
        for range in index {
            let maxLength = max(String(range.lowerBound).count, String(range.upperBound).count)
            let cardNumberSegment = cardNumberString.withoutNonNumericCharacters.prefix(maxLength)
            if let cardNumberInteger = Int(cardNumberSegment), range.contains(cardNumberInteger) {
                return mapping[range]
            }
        }
        return nil
    }
}

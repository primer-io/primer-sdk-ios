//
//  ResultViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import PrimerSDK

class ResultViewController: UIViewController {
    
    static func instantiate(data: [Data]) -> ResultViewController {
        let rvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
        rvc.data = data
        return rvc
    }
    
    var data: [Data]!
    
    @IBOutlet weak var responseStatus: UILabel!
    @IBOutlet weak var requiredActionsLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let paymentResponses = data.compactMap({ try? JSONDecoder().decode(Payment.Response.self, from: $0) }).sorted(by: { $0.dateStr ?? "" < $1.dateStr ?? "" })
        responseStatus.text = paymentResponses.last?.status.rawValue
        responseStatus.font = .systemFont(ofSize: 17, weight: .medium)
        switch paymentResponses.last?.status {
        case .declined,
                .failed:
            responseStatus.textColor = .red
        case .authorized,
                .settled:
            responseStatus.textColor = .green
        case .pending:
            responseStatus.textColor = .orange
        case .none:
            break
        }
        
        var requiredActionsNames = ""
        requiredActionsNames = paymentResponses.filter({ $0.requiredAction != nil }).compactMap({ $0.requiredAction!.name.rawValue }).joined(separator: ", ").uppercased().folding(options: .diacriticInsensitive, locale: .current)
        requiredActionsLabel.text = requiredActionsNames
        
        var responsesStr = ""
        for paymentResponseData in data {
            responsesStr += (paymentResponseData.prettyPrintedJSONString as String? ?? "") + "\n\n----\n\n"
        }

        let responseAttrStr = NSMutableAttributedString(string: responsesStr, attributes: nil)
        
        let settledRanges = responsesStr.allRanges(of: Payment.Response.Status.settled.rawValue).compactMap({ $0.toNSRange(in: responsesStr) })
        settledRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemGreen, range: $0) })
        settledRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: $0) })
        
        let authorizedRanges = responsesStr.allRanges(of: Payment.Response.Status.authorized.rawValue).compactMap({ $0.toNSRange(in: responsesStr) })
        authorizedRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemGreen, range: $0) })
        authorizedRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: $0) })
        
        let declinedRanges = responsesStr.allRanges(of: Payment.Response.Status.declined.rawValue).compactMap({ $0.toNSRange(in: responsesStr) })
        declinedRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemRed, range: $0) })
        declinedRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: $0) })
        
        let failedRanges = responsesStr.allRanges(of: Payment.Response.Status.failed.rawValue).compactMap({ $0.toNSRange(in: responsesStr) })
        failedRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemRed, range: $0) })
        failedRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: $0) })
        
        let pendingRanges = responsesStr.allRanges(of: Payment.Response.Status.pending.rawValue).compactMap({ $0.toNSRange(in: responsesStr) })
        pendingRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemOrange, range: $0) })
        pendingRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: $0) })
        
        if let amount = paymentResponses.last?.amount, let currencyCode = paymentResponses.last?.currencyCode {
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .currency
            currencyFormatter.currencySymbol = ""

            let amountDbl = Double(amount) / 100
            let amountStr = currencyFormatter.string(from: NSNumber(value: amountDbl))!
            
            amountLabel.text = "\(currencyCode) \(amountStr)"
            
            let amountRanges = responsesStr.allRanges(of: String(amount)).compactMap({ $0.toNSRange(in: responsesStr) })
            amountRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemBlue, range: $0) })
            amountRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: $0) })
        }
        
        
        responseTextView.attributedText = responseAttrStr
    }
    
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        
        return prettyPrintedString
    }
}

extension String {
    public func allRanges(
        of aString: String,
        options: String.CompareOptions = [],
        range: Range<String.Index>? = nil,
        locale: Locale? = nil
    ) -> [Range<String.Index>] {
        
        // the slice within which to search
        let slice = (range == nil) ? self[...] : self[range!]
        
        var previousEnd = self.startIndex
        var ranges = [Range<String.Index>]()
        
        while let r = slice.range(
            of: aString, options: options,
            range: previousEnd ..< self.endIndex,
            locale: locale
        ) {
            if previousEnd != self.endIndex { // don't increment past the end
                previousEnd = self.index(after: r.lowerBound)
            }
            ranges.append(r)
        }
        
        return ranges
    }
    
    public func allRanges(
        of aString: String,
        options: String.CompareOptions = [],
        range: Range<String.Index>? = nil,
        locale: Locale? = nil
    ) -> [Range<Int>] {
        return allRanges(of: aString, options: options, range: range, locale: locale)
            .map(indexRangeToIntRange)
    }
    
    
    private func indexRangeToIntRange(_ range: Range<String.Index>) -> Range<Int> {
        return indexToInt(range.lowerBound) ..< indexToInt(range.upperBound)
    }
    
    private func indexToInt(_ index: String.Index) -> Int {
        return self.distance(from: self.startIndex, to: index)
    }

}

extension Range where Bound == String.Index {
    func toNSRange(in text: String) -> NSRange {
        return NSRange(self, in: text)
    }
}

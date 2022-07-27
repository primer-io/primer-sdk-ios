//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import UIKit
import PrimerSDK

class HUCResultViewController: UIViewController {
    
    static func instantiate(data: [Data]) -> HUCResultViewController {
        let rvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as! HUCResultViewController
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
        case .failed:
            responseStatus.textColor = .red
        case .success:
            responseStatus.textColor = .green
        case .pending:
            responseStatus.textColor = .orange
        default:
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
        
        let successRanges = responsesStr.allRanges(of: Payment.Response.Status.success.rawValue).compactMap({ $0.toNSRange(in: responsesStr) })
        successRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.systemGreen, range: $0) })
        successRanges.forEach({ responseAttrStr.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 15, weight: .semibold), range: $0) })
                
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

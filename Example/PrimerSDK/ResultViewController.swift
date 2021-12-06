//
//  ResultViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    
    static func instantiate(data: [Data]) -> ResultViewController {
        let rvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
        rvc.data = data
        return rvc
    }
    
    var data: [Data]!
    
    @IBOutlet weak var responseStatus: UILabel!
    @IBOutlet weak var requiredActionsLabel: UILabel!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let paymentResponses = data.compactMap({ try? JSONDecoder().decode(Payment.Response.self, from: $0) }).sorted(by: { $0.dateStr ?? "" < $1.dateStr ?? "" })
        responseStatus.text = paymentResponses.last?.status.rawValue
        responseStatus.font = .systemFont(ofSize: 17, weight: .medium)
        switch paymentResponses.last?.status {
        case .declined:
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
        requiredActionsNames = paymentResponses.filter({ $0.requiredAction != nil }).compactMap({ $0.requiredAction!.name }).joined(separator: ", ").uppercased()
        requiredActionsLabel.text = requiredActionsNames
        
        var responsesStr = ""
        for paymentResponseData in data {
            responsesStr += (paymentResponseData.prettyPrintedJSONString as String? ?? "") + "\n\n"
        }
        
        responseTextView.text = responsesStr
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

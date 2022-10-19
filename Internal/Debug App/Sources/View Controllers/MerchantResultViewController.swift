//
//  ResultViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import PrimerSDK

class MerchantResultViewController: UIViewController {
    
    static func instantiate(
        checkoutData: [String]?,
        error: Error?,
        logs: [String]
    ) -> MerchantResultViewController {
        let rvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantResultViewController") as! MerchantResultViewController
        rvc.checkoutData = checkoutData
        rvc.logs = logs
        return rvc
    }
    
    var checkoutData: [String]?
    var logs: [String] = []
    
    @IBOutlet weak var responseStatus: UILabel!
    
    @IBOutlet weak var responseStackView: UIStackView!
    @IBOutlet weak var logsTextView: UITextView!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.responseStatus.text = self.checkoutData?.payment?.paymentFailureReason != nil ? self.checkoutData?.payment?.paymentFailureReason?.rawValue : "SUCCESS"
        self.responseStatus.font = .systemFont(ofSize: 17, weight: .medium)
        self.responseStatus.textColor = .green

        let logsText: String = logs.joined(separator: "\n\n")
        
        if logsText.count > 0 {
            self.logsTextView.text = logsText
        }
        
        let checkoutDataText: String = (checkoutData ?? []).joined(separator: "\n\n---\n\n")
        
        if checkoutDataText.count > 0 {
            responseTextView.attributedText = NSAttributedString(string: checkoutDataText)
        }
    }
    
}

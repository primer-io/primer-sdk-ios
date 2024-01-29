//
//  ResultViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import PrimerSDK

final class MerchantResultViewController: UIViewController {
    
    static func instantiate(
        checkoutData: PrimerCheckoutData?,
        error: Error?,
        logs: [String]
    ) -> MerchantResultViewController {
        let rvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantResultViewController") as! MerchantResultViewController
        rvc.checkoutData = checkoutData
        rvc.error = error
        rvc.logs = logs
        return rvc
    }
    
    var checkoutData: PrimerCheckoutData?
    var error: Error?
    var logs: [String] = []
    
    @IBOutlet weak var responseStatus: UILabel!
    
    @IBOutlet weak var responseStackView: UIStackView!
    @IBOutlet weak var logsTextView: UITextView!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        responseStatus.font = .systemFont(ofSize: 17, weight: .medium)
        responseStatus.textColor = .green
        
        if logs.count > 0 {
            if let data = try? JSONSerialization.data(withJSONObject: logs) {
                if let prettyNSStr = data.prettyPrintedJSONString {
                    if let prettyStr = prettyNSStr as? String {
                        logsTextView.text = prettyStr
                    } else {
                        logsTextView.text = "[\"Failed to case NSString to String [WebDriverIO]\"]"
                    }
                } else {
                    logsTextView.text = "[\"Failed to create pretty string from logs\"]"
                }
            } else {
                logsTextView.text = "[\"Failed to convert logs to data\"]"
            }
        } else {
            logsTextView.text = "[\"No logs received\"]"
        }

        if let checkoutData {
            if let data = try? JSONEncoder().encode(checkoutData) {
                if let prettyNSStr = data.prettyPrintedJSONString {
                    if let prettyStr = prettyNSStr as? String {
                        responseTextView.text = prettyStr
                    } else {
                        responseTextView.text = "[\"Failed to case NSString to String [WebDriverIO]\"]"
                    }
                } else {
                    responseTextView.text = "[\"Failed to create pretty string from checkout data\"]"
                }
            } else {
                responseTextView.text = "[\"Failed to convert logs to data\"]"
            }
        } else if let error = self.error {
            responseTextView.text = "[\"\(error.localizedDescription)\"]"
        } else {
            responseTextView.text = "[\"No checkout data or error received\"]"
        }
    }
}

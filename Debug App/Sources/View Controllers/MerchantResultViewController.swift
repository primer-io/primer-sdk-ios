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

        var error: PrimerErrorEncodable?

        if let primerError = self.error as? PrimerError {
            let encodable = PrimerErrorEncodable(errorId: primerError.errorId,
                                                 errorDescription: primerError.localizedDescription,
                                                 diagnosticId: primerError.diagnosticsId,
                                                 recoverySuggestion: primerError.recoverySuggestion)
            error = encodable
        }

        if error != nil || checkoutData != nil {
            let paymentEncodable = PrimerPaymentResultEncodable(id: checkoutData?.payment?.id, 
                                                          orderId: checkoutData?.payment?.orderId)
            let encodable = PrimerResultEncodable(payment: paymentEncodable, error: error)
            guard let data = try? JSONEncoder().encode(encodable), let string = String(data: data, encoding: .utf8) else {
                responseTextView.text = "[\"Couldn't encode result to JSON\"]"
                return
            }
            responseTextView.text = string
        } else if self.error != nil {
            responseTextView.text = "[\"\(error?.errorDescription ?? "unknown")\"]"
        } else {
            responseTextView.text = "[\"No checkout data or error received\"]"
        }

        
        responseStatus.font = .systemFont(ofSize: 17, weight: .medium)
        responseStatus.textColor = error == nil ? .green : .red
        responseStatus.text = error == nil ? "Success" : "Failure"

        if logs.count > 0 {
            if let data = try? JSONSerialization.data(withJSONObject: logs) {
                if let prettyNSStr = data.prettyPrintedJSONString as? String {
                    logsTextView.text = prettyNSStr
                } else {
                    logsTextView.text = "[\"Failed to create pretty string from logs\"]"
                }
            } else {
                logsTextView.text = "[\"Failed to convert logs to data\"]"
            }
        } else {
            logsTextView.text = "[\"No logs received\"]"
        }
    }
}

private struct PrimerResultEncodable: Encodable {
    let payment: PrimerPaymentResultEncodable?
    let error: PrimerErrorEncodable?
}

private struct PrimerErrorEncodable: Encodable {
    let errorId: String
    let errorDescription: String
    let diagnosticId: String
    let recoverySuggestion: String?
}

private struct PrimerPaymentResultEncodable: Encodable {
    let id: String?
    let orderId: String?
}

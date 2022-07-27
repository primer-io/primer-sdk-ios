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

class ResultViewController: UIViewController {
    
    static func instantiate(data: PrimerCheckoutData) -> ResultViewController {
        let rvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
        rvc.data = data
        return rvc
    }
    
    var data: PrimerCheckoutData!
    
    // To utilize with HUC
    @IBOutlet weak var amountStackView: UIStackView!
    @IBOutlet weak var actionsStackView: UIStackView!
    @IBOutlet weak var responseStatus: UILabel!
    @IBOutlet weak var requiredActionsLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    // Valid for both the HUC and standard implementation
    @IBOutlet weak var responseStackView: UIStackView!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.amountStackView.isHidden = true
        self.actionsStackView.isHidden = true
        
        responseStatus.text = "SUCCESS"
        responseStatus.font = .systemFont(ofSize: 17, weight: .medium)
        responseStatus.textColor = .green

        guard let dictionary = try? data.asDictionary(),
              let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
              let jsonString = jsonData.prettyPrintedJSONString as? String else {
            responseTextView.text = "Couln't decode CheckoutData response"
            return
        }
        
        responseTextView.attributedText = NSAttributedString(string: jsonString)
    }
    
}

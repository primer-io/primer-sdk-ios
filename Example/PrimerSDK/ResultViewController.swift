//
//  ResultViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 3/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    
    static func instantiate(data: Data) -> ResultViewController {
        let rvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
        rvc.data = data
        return rvc
    }
    
    var data: Data!
    
    @IBOutlet weak var responseStatus: UILabel!
    @IBOutlet weak var responseTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let responseStr = data.prettyPrintedJSONString as? String
        responseTextView.text = responseStr
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

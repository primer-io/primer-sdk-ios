//
//  UIAlertController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/3/21.
//

import UIKit

extension UIAlertController {
    
    static func errorAlert(title: String?, message: String?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        return alert
    }
    
}

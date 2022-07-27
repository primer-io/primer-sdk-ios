//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import PrimerSDK
import UIKit

// MARK: - HELPERS

extension UIViewController {
    
    func keyboardWillShow(notification: NSNotification) {
        let height = UIScreen.main.bounds.height - view.frame.height
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y.rounded() == height.rounded() {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

}

//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import UIKit

class PaymentMethodCell: UITableViewCell {
    
    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodTitleLabel: UILabel!
    
    func configure(title: String, image: UIImage?) {
        self.paymentMethodImageView.image = image
        self.paymentMethodTitleLabel.text = title
    }
    
}

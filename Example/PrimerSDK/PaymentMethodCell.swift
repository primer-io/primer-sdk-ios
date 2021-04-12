//
//  PaymentMethodCell.swift
//  PrimerSDK_Example
//
//  Created by Evangelos Pittas on 12/4/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
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

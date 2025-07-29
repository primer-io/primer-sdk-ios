//
//  PaymentMethodCell.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

class PaymentMethodCell: UITableViewCell {

    @IBOutlet weak var paymentMethodImageView: UIImageView!
    @IBOutlet weak var paymentMethodTitleLabel: UILabel!

    func configure(title: String, image: UIImage?) {
        self.paymentMethodImageView.image = image
        self.paymentMethodTitleLabel.text = title
    }

}

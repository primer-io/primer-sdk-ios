//
//  MerchantNewLineItemViewController.swift
//  Debug App
//
//  Created by Evangelos Pittas on 8/2/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit

class MerchantNewLineItemViewController: UIViewController {
    
    class func instantiate(lineItem: ClientSessionRequestBody.Order.LineItem?) -> MerchantNewLineItemViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantNewLineItemViewController") as! MerchantNewLineItemViewController
        vc.initialLineItem = lineItem
        return vc
    }
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    var initialLineItem: ClientSessionRequestBody.Order.LineItem?
    var onLineItemAdded: ((_ lineItem: ClientSessionRequestBody.Order.LineItem) -> Void)?
    var onLineItemEdited: ((_ lineItem: ClientSessionRequestBody.Order.LineItem) -> Void)?
    var onLineItemDeleted: ((_ lineItem: ClientSessionRequestBody.Order.LineItem) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.text = initialLineItem?.description
        quantityTextField.text = initialLineItem?.quantity != nil ? "\(initialLineItem!.quantity!)" : nil
        priceTextField.text = initialLineItem?.amount != nil ? "\(initialLineItem!.amount!)" : nil
        
        if initialLineItem != nil {
            doneButton.setTitle("Edit Line Item", for: .normal)
            deleteButton.isHidden = false
        } else {
            doneButton.setTitle("Add Line Item", for: .normal)
            deleteButton.isHidden = true
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty,
              let quantityStr = quantityTextField.text, let quantity = Int(quantityStr), quantity > 0,
              let priceStr = priceTextField.text, let price = Int(priceStr), price > 0
        else {
            return
        }
        
        let lineItem = ClientSessionRequestBody.Order.LineItem(
            itemId: "item-" + String.randomString(length: 4),
            description: name,
            amount: price,
            quantity: quantity)
        
        if initialLineItem != nil {
            onLineItemEdited?(lineItem)
            navigationController?.popViewController(animated: true)
            
        } else {
            onLineItemAdded?(lineItem)
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        guard let lineItem = initialLineItem else { return }
        onLineItemDeleted?(lineItem)
        navigationController?.popViewController(animated: true)
    }
}

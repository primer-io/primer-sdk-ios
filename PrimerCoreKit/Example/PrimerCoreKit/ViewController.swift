//
//  ViewController.swift
//  PrimerCoreKit
//
//  Created by Evangelos Pittas on 05/11/2021.
//  Copyright (c) 2021 Evangelos Pittas. All rights reserved.
//

import PrimerCoreKit
import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textField: PrimerPCITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func viewTapped(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func hackDelegateButtonTapped(_ sender: Any) {
        sneakySetTextFieldDelegate()
    }
    
    @IBAction func sneakyGetTextButtonTapped(_ sender: Any) {
        sneakyGetTextFieldText()
    }
    
    
    func sneakySetTextFieldDelegate() {
        ((textField.subviews.first!.subviews.first!.subviews.first!.subviews.first as! UIStackView).arrangedSubviews.first as? UITextField)?.delegate = self
    }
    
    func sneakyGetTextFieldText() {
//        print(textField.textField)
        
        let text = (((view.subviews.first as! UIView).subviews[0].subviews[0].subviews[0].subviews[0] as! UIStackView).arrangedSubviews[0] as! UITextField).text
        print("TextField text: \(text)")
    }
    
    func breakMe() {
        // po (((view.subviews.first as! UIView).subviews[0].subviews[0].subviews[0].subviews[0] as! UIStackView).arrangedSubviews[0] as! UITextField).text
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("I manageed to intercept the text field. String is: \(string)")
        return true
    }
}

//class SneakyTextField: PrimerPCITextField {
//
//}


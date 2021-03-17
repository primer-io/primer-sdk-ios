//
//  UIViewExtensions.swift
//  PrimerScannerDemo
//
//  Created by Carl Eriksson on 29/11/2020.
//

import UIKit

extension UIView {
    func pin(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
//        let height = UIScreen.main.bounds.height - frame.height
//        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
////            if self.frame.origin.y.rounded() == height.rounded() {
////                self.frame.origin.y -= keyboardSize.height
////            }
//        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
//        let height = UIScreen.main.bounds.height - frame.height
////        if self.frame.origin.y.rounded() != height.rounded() {
////            self.frame.origin.y = height.rounded()
////        }
    }
}

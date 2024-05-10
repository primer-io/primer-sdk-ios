//
//  UIViewExtensions.swift
//  PrimerScannerDemo
//
//  Created by Carl Eriksson on 29/11/2020.
//

import Foundation
import UIKit

internal class PrimerView: UIView {

    func pin(to superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }

    func removeSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }

}

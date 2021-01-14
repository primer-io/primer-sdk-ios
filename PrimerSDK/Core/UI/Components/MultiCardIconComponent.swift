//
//  MultiCardIconComponent.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 04/01/2021.
//

import UIKit

class MultiCardIconComponent: UIView {
    
    let visaIconView = UIImageView(image: UIImage(named: "visa"))
    let discoverIconView = UIImageView(image: UIImage(named: "discover"))
    let amexIconView = UIImageView(image: UIImage(named: "amex"))
    let masterCardIconView = UIImageView(image: UIImage(named: "masterCard"))
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(visaIconView)
        addSubview(discoverIconView)
        addSubview(amexIconView)
        addSubview(masterCardIconView)
        
//        guard let visaSize = visaIconView.image?.size else { return }
//        guard let discoverSize = discoverIconView.image?.size else { return }
//        guard let amexSize = amexIconView.image?.size else { return }
//        guard let masterCardSize = masterCardIconView.image?.size else { return }
        
        visaIconView.frame = CGRect(x: 3, y: 0, width: 30, height: 20)
        discoverIconView.frame = CGRect(x: 30 + 6, y: 0, width: 30, height: 20)
        amexIconView.frame = CGRect(x: 60 + 9, y: 0, width: 30, height: 20)
        masterCardIconView.frame = CGRect(x: 90 + 12, y: 0, width: 30, height: 20)
        
//        anchorVisaIconView()
//        anchorDiscoverIconView()
//        anchorAmexIconView()
//        anchorMasterCardIconView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureVisa() {
        
    }
    
    func configureDiscover() {
        
    }
    
    func configureAmex() {
        
    }
    
    func configureMasterCard() {
        
    }
    
//    func anchorVisaIconView() {
//        visaIconView.translatesAutoresizingMaskIntoConstraints = false
//        visaIconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12).isActive = true
//        visaIconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//    }
//
//    func anchorDiscoverIconView() {
//        discoverIconView.translatesAutoresizingMaskIntoConstraints = false
//        discoverIconView.trailingAnchor.constraint(equalTo: visaIconView.trailingAnchor, constant: -12).isActive = true
//        discoverIconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//    }
//
//    func anchorAmexIconView() {
//        amexIconView.translatesAutoresizingMaskIntoConstraints = false
//        amexIconView.trailingAnchor.constraint(equalTo: discoverIconView.trailingAnchor, constant: -12).isActive = true
//        amexIconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//    }
//
//    func anchorMasterCardIconView() {
//        masterCardIconView.translatesAutoresizingMaskIntoConstraints = false
//        masterCardIconView.trailingAnchor.constraint(equalTo: amexIconView.trailingAnchor, constant: -12).isActive = true
//        masterCardIconView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
//    }

}

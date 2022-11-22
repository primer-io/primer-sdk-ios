//
//  UIImageView+Squared.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/11/22.
//

#if canImport(UIKit)

import UIKit

extension UIImageView {
    
    static func makeSquaredIconImageView(from image: UIImage?, withDimension dimension: CGFloat = PrimerDimensions.Icon.squaredDimension) -> UIImageView? {
        guard let squareLogo = image else { return nil }
        let imgView = UIImageView()
        imgView.image = squareLogo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: dimension).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: dimension).isActive = true
        return imgView
    }

}

#endif

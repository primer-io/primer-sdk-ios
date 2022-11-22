//
//  PrimerFormView+Helpers.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/11/22.
//

#if canImport(UIKit)

import UIKit

extension PrimerFormView {
    
    static func makeLogoAndMessageInfoView(logo: UIImage?, message: String) -> PrimerFormView {
        
        // The top logo
        
        let logoImageView = UIImageView(image: logo)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        logoImageView.clipsToBounds = true
        logoImageView.contentMode = .scaleAspectFit
        
        // Message string
        
        let completeYourPaymentLabel = UILabel()
        completeYourPaymentLabel.numberOfLines = 0
        completeYourPaymentLabel.textAlignment = .center
        completeYourPaymentLabel.text = message
        completeYourPaymentLabel.font = UIFont.systemFont(ofSize: PrimerDimensions.Font.label)
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        completeYourPaymentLabel.textColor = theme.text.title.color
        
        let views = [[logoImageView],
                     [completeYourPaymentLabel]]
        
        return PrimerFormView(formViews: views)
    }
}

#endif

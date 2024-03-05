//
//  CVVRecaptureViewModel.swift
//  PrimerSDK
//
//  Created by Boris on 29.2.24..
//

import Foundation

class CVVRecaptureViewModel {

    var didSubmitCvv: ((String) -> Void)?
    var cardButtonViewModel: CardButtonViewModel!
    var onContinueButtonStateChange: ((Bool) -> Void)?

    var isValidCvv: Bool = false {
        didSet {
            onContinueButtonStateChange?(isValidCvv)
        }
    }

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    // Logic to handle continue button tap
    func continueButtonTapped(with cvv: String) {
        if isValidCvv {
            didSubmitCvv?(cvv)
        }
    }
}

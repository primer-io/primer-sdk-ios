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
            updateContinueButtonState()
        }
    }

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    // Logic to handle continue button tap
    func continueButtonTapped(with cvv: String) {
        if isValidCvv {
            didSubmitCvv?(cvv)
        }
    }

    // Update UI based on CVV validation
    private func updateContinueButtonState() {
        // This closure can be used by the ViewController to update the continue button's state
        onContinueButtonStateChange?(isValidCvv)
    }
}

//
//  CVVRecaptureViewController.swift
//  PrimerSDK
//
//  Created by Boris on 28.2.24..
//

import UIKit

class CVVRecaptureViewController: UIViewController {

    var didSubmitCvv: ((String) -> Void)?
    var cardButtonViewModel: CardButtonViewModel!

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let explanationLabel = UILabel()
    private let imageView = UIImageView()
    private let cardNumberLabel = UILabel()
    private var cvvField: PrimerCVVFieldView!
    private var cvvContainerView: PrimerCustomFieldView!
    private let continueButton = PrimerButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        title = "Enter CVV"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = cvvField.becomeFirstResponder()
    }

    // MARK: - View Setup Functions
    private let padding: CGFloat = 16.0
    private let height: CGFloat = 48.0

    private func setupViews() {
        setupExplanationLabel()
        setupImageView()
        setupCardNumberLabel()
        setupCVVContainerView()
        setupContinueButton(with: "Continue")
    }

    private func setupExplanationLabel() {
        explanationLabel.text = "Input the 3 or 4 digit security code on your card for a secure payment."
        explanationLabel.numberOfLines = 0
        explanationLabel.textColor = theme.text.body.color
        explanationLabel.font = .systemFont(ofSize: CGFloat(theme.text.body.fontSize))
        view.addSubview(explanationLabel)
        activateExplanationLabelConstraints()
    }

    private func setupImageView() {
        imageView.image = cardButtonViewModel.imageName.image
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        activateImageViewConstraints()
    }

    private func setupCardNumberLabel() {
        cardNumberLabel.text = cardButtonViewModel.last4
        cardNumberLabel.textColor = theme.text.body.color
        cardNumberLabel.font = .systemFont(ofSize: CGFloat(theme.text.body.fontSize), weight: .bold)
        view.addSubview(cardNumberLabel)
        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        activateCardNumberLabelConstraints()
    }

    private func setupCVVContainerView() {
        cvvField = PrimerCVVField.cvvFieldViewWithDelegate(self)
        cvvField.cardNetwork = CardNetwork(cardNetworkStr: self.cardButtonViewModel.network)
        cvvField.isValid = { text in
            let cardNetwork = CardNetwork(cardNetworkStr: self.cardButtonViewModel.network)
            return !text.isEmpty && text.isValidCVV(cardNetwork: cardNetwork)
        }
        cvvContainerView = PrimerCVVField.cvvContainerViewFieldView(cvvField)
        view.addSubview(cvvContainerView)
        cvvContainerView.translatesAutoresizingMaskIntoConstraints = false
        activateCVVContainerViewConstraints()
    }

    private func setupContinueButton(with title: String) {
        continueButton.layer.cornerRadius = 4
        continueButton.setTitle(title, for: .normal)
        continueButton.setTitleColor(theme.mainButton.text.color, for: .normal)
        continueButton.titleLabel?.font = .boldSystemFont(ofSize: 19)
        continueButton.backgroundColor = theme.mainButton.color(for: .enabled)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        continueButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        continueButton.isEnabled = false
        continueButton.backgroundColor = theme.mainButton.color(for: .disabled)
        view.addSubview(continueButton)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        activateContinueButtonConstraints()
    }

    private func activateExplanationLabelConstraints() {
        explanationLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            explanationLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            explanationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            explanationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }

    private func activateImageViewConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: explanationLabel.bottomAnchor, constant: 24),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            imageView.widthAnchor.constraint(equalToConstant: 56),
            imageView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func activateCardNumberLabelConstraints() {
        NSLayoutConstraint.activate([
            cardNumberLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            cardNumberLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: padding)
        ])
    }

    private func activateCVVContainerViewConstraints() {
        NSLayoutConstraint.activate([
            cvvContainerView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            cvvContainerView.leadingAnchor.constraint(equalTo: cardNumberLabel.trailingAnchor, constant: 24),
            cvvContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }

    private func activateContinueButtonConstraints() {
        NSLayoutConstraint.activate([
            continueButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: padding)
        ])
    }

    @objc private func continueButtonTapped() {
        didSubmitCvv?(cvvField.cvv)
    }
}

extension CVVRecaptureViewController: PrimerTextFieldViewDelegate {

    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        print(isValid!)
        continueButton.isEnabled = isValid ?? true
        let continueButtonColor = theme.mainButton.color(for: (isValid ?? true) ? .enabled : .disabled)
        continueButton.backgroundColor = continueButtonColor
    }
}

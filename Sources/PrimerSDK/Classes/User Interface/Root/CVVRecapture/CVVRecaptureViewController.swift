//
//  CVVRecaptureViewController.swift
//  PrimerSDK
//
//  Created by Boris on 28.2.24..
//

import UIKit

class CVVRecaptureViewController: UIViewController {

    var viewModel: CVVRecaptureViewModel
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private let explanationLabel = UILabel()
    private let imageView = UIImageView()
    private let cardNumberLabel = UILabel()
    private var cvvField: PrimerCVVFieldView!
    private var cvvContainerView: PrimerCustomFieldView!
    private let continueButton = PrimerButton()

    // Designated initializer
    init(viewModel: CVVRecaptureViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    // Required initializer for decoding
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = cvvField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Back button tap
        if self.isMovingFromParent {
            let backButtonTapEvent = Analytics.Event.ui(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType:viewModel.cardButtonViewModel.paymentMethodType.rawValue,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .back,
                objectClass: "\(Self.self)",
                place: .cvvRecapture
            )
            Analytics.Service.record(event: backButtonTapEvent)
        }

        let dismissEvent = Analytics.Event.ui(
            action: .dismiss,
            context: Analytics.Event.Property.Context(
                issuerId: nil,
                paymentMethodType:viewModel.cardButtonViewModel.paymentMethodType.rawValue,
                url: nil),
            extra: nil,
            objectType: .view,
            objectId: nil,
            objectClass: "\(Self.self)",
            place: .cvvRecapture
        )
        Analytics.Service.record(event: dismissEvent)
    }

    private func bindViewModel() {
        viewModel.onContinueButtonStateChange = { [weak self] isEnabled in
            if self?.continueButton.isAnimating == true { return }
            self?.continueButton.isEnabled = isEnabled
            let continueButtonColor = self?.theme.mainButton.color(for: isEnabled ? .enabled : .disabled)
            self?.continueButton.backgroundColor = continueButtonColor
        }
    }

    // MARK: - View Setup Functions
    private let padding: CGFloat = 16.0
    private let height: CGFloat = 48.0
    private let defaultElementDistance: CGFloat = 24.0
    private func setupViews() {
        title = Strings.CVVRecapture.title
        setupExplanationLabel()
        setupImageView()
        setupCardNumberLabel()
        setupCVVContainerView()
        setupContinueButton(with: Strings.CVVRecapture.buttonTitle)
    }

    private func setupExplanationLabel() {
        let explanationText = String(format: Strings.CVVRecapture.explanation, viewModel.cvvLength)
        explanationLabel.text = explanationText
        explanationLabel.numberOfLines = 0
        explanationLabel.textColor = theme.text.body.color
        explanationLabel.font = .systemFont(ofSize: CGFloat(theme.text.body.fontSize))
        view.addSubview(explanationLabel)
        activateExplanationLabelConstraints()
    }

    private func setupImageView() {
        let networkIcon = CardNetwork(cardNetworkStr: viewModel.cardButtonViewModel.network).icon
        imageView.image = networkIcon
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        activateImageViewConstraints()
    }

    private func setupCardNumberLabel() {
        cardNumberLabel.text = viewModel.cardButtonViewModel.last4
        cardNumberLabel.textColor = theme.text.body.color
        cardNumberLabel.font = .systemFont(ofSize: CGFloat(theme.text.body.fontSize), weight: .bold)
        view.addSubview(cardNumberLabel)
        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        activateCardNumberLabelConstraints()
    }

    private func setupCVVContainerView() {
        cvvField = PrimerCVVField.cvvFieldViewWithDelegate(self)
        cvvField.cardNetwork = CardNetwork(cardNetworkStr: viewModel.cardButtonViewModel.network)
        cvvField.isValid = { text in
            let cardNetwork = CardNetwork(cardNetworkStr: self.viewModel.cardButtonViewModel.network)
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
        continueButton.accessibilityIdentifier = "vaulted_payment_method_cvv_btn_submit"
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
            imageView.topAnchor.constraint(equalTo: explanationLabel.bottomAnchor, constant: defaultElementDistance),
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
            cvvContainerView.leadingAnchor.constraint(equalTo: cardNumberLabel.trailingAnchor, constant: defaultElementDistance),
            cvvContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }

    private func activateContinueButtonConstraints() {
        NSLayoutConstraint.activate([
            continueButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: defaultElementDistance),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            continueButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: padding)
        ])
    }

    @objc private func continueButtonTapped() {
        continueButton.startAnimating()
        viewModel.continueButtonTapped(with: cvvField.cvv)
    }
}

extension CVVRecaptureViewController: PrimerTextFieldViewDelegate {
    func primerTextFieldView(_ primerTextFieldView: PrimerTextFieldView, isValid: Bool?) {
        viewModel.isValidCvv = isValid ?? true
    }
}

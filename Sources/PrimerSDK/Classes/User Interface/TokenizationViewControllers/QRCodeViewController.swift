//
//  QRCodeViewController.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

final class QRCodeViewController: PrimerFormViewController {

    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    private var viewModel: QRCodeTokenizationViewModel!
    private var amountLabel: UILabel! = UILabel()
    private(set) var subtitle: String?

    deinit {
        viewModel.cancel()
        viewModel = nil
    }

    init(viewModel: QRCodeTokenizationViewModel) {
        self.viewModel = viewModel
        super.init()
        self.titleImage = viewModel.uiModule.logo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let context = AnalyticsContext(paymentMethodType: viewModel.config.type)
        postUIEvent(.view, context: context, type: .view, in: .bankSelectionList)

        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false

        verticalStackView.spacing = 5

        renderAmount()
        renderCopies()
        renderQRCode()
    }

    private func renderAmount() {
        let universalCheckoutViewModel: UniversalCheckoutViewModelProtocol = UniversalCheckoutViewModel()

        if let amountStr = universalCheckoutViewModel.amountStr {
            amountLabel.translatesAutoresizingMaskIntoConstraints = false
            amountLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
            amountLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
            amountLabel.text = amountStr
            amountLabel.textAlignment = .left
            amountLabel.textColor = theme.text.amountLabel.color
            verticalStackView.addArrangedSubview(amountLabel)
        }
    }

    private func renderCopies() {
        let separatorView = PrimerView()
        verticalStackView.addArrangedSubview(separatorView)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = Strings.QRCodeView.scanToCodeTitle
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        titleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = Strings.QRCodeView.uploadScreenshotTitle
        subtitleLabel.numberOfLines = 2
        subtitleLabel.font = UIFont.systemFont(ofSize: 15)
        subtitleLabel.textColor = theme.text.title.color
        verticalStackView.addArrangedSubview(subtitleLabel)
    }

    private func renderQRCode() {
        guard let qrCodeStr = viewModel.qrCode else { return }

        let separatorView = PrimerView()
        verticalStackView.addArrangedSubview(separatorView)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 10).isActive = true

        var qrCodeImageView = PrimerImageView()
        if qrCodeStr.isHttpOrHttpsURL == true, let qrCodeURL = URL(string: qrCodeStr) {
            qrCodeImageView = PrimerImageView(from: qrCodeURL)
        } else if let qrCodeImg = convertBase64StringToImage(qrCodeStr) {
            qrCodeImageView.image = qrCodeImg
        }
        qrCodeImageView.accessibilityIdentifier = "qrCode"
        qrCodeImageView.accessibilityHint = Strings.QRCodeView.qrCodeImageSubtitle
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeImageView.widthAnchor.constraint(equalToConstant: 270).isActive = true
        qrCodeImageView.heightAnchor.constraint(equalToConstant: 270).isActive = true

        let qrCodeOutlinerView = PrimerView()
        qrCodeOutlinerView.addSubview(qrCodeImageView)
        qrCodeOutlinerView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeOutlinerView.widthAnchor.constraint(equalToConstant: 290).isActive = true
        qrCodeOutlinerView.heightAnchor.constraint(equalToConstant: 290).isActive = true
        qrCodeOutlinerView.centerXAnchor.constraint(equalTo: qrCodeImageView.centerXAnchor).isActive = true
        qrCodeOutlinerView.centerYAnchor.constraint(equalTo: qrCodeImageView.centerYAnchor).isActive = true
        qrCodeOutlinerView.layer.borderColor = UIColor.lightGray.cgColor
        qrCodeOutlinerView.layer.borderWidth = 1.0
        qrCodeOutlinerView.layer.cornerRadius = 4.0

        let qrCodeContainerView = PrimerView()
        qrCodeContainerView.addSubview(qrCodeOutlinerView)
        qrCodeContainerView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeOutlinerView.topAnchor.constraint(equalTo: qrCodeContainerView.topAnchor).isActive = true
        qrCodeOutlinerView.bottomAnchor.constraint(equalTo: qrCodeContainerView.bottomAnchor).isActive = true
        qrCodeOutlinerView.centerXAnchor.constraint(equalTo: qrCodeContainerView.centerXAnchor).isActive = true
        verticalStackView.addArrangedSubview(qrCodeContainerView)

        let bottomSeparatorView = PrimerView()
        verticalStackView.addArrangedSubview(bottomSeparatorView)
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorView.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }

    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }

    func convertBase64StringToImage(_ imageBase64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: imageBase64String, options: .init(rawValue: 0)) else { return nil }
        return UIImage(data: imageData)
    }
}

//
//  QRCodeViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/1/22.
//

#if canImport(UIKit)

import UIKit

internal class QRCodeViewController: PrimerFormViewController {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    private var viewModel: QRCodeTokenizationViewModel!
    private var amountLabel: UILabel! = UILabel()
    internal private(set) var subtitle: String?
    
    deinit {
        viewModel.cancel()
        viewModel = nil
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    init(viewModel: QRCodeTokenizationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.titleImage = viewModel.uiModule.originalImage
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewEvent = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .view,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.viewModel.config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .view,
                objectId: nil,
                objectClass: "\(Self.self)",
                place: .bankSelectionList))
        Analytics.Service.record(event: viewEvent)

        view.backgroundColor = theme.view.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
         
        verticalStackView.spacing = 5
        
        renderAmount()
        renderCopies()
        renderQRCode()
    }
    
    private func renderAmount() {
        let checkoutViewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
        
        if let amountStr = checkoutViewModel.amountStringed {
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
        
        let qrCodeImageView = PrimerImageView()
        if qrCodeStr.isURL == true, let qrCodeURL = URL(string: qrCodeStr) {
            qrCodeImageView.downloaded(from: qrCodeURL)
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

#endif


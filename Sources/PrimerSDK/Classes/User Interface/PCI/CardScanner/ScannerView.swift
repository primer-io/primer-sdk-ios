#if canImport(UIKit)

import UIKit

internal protocol ScannerViewDelegate: AnyObject {
    func cancel()
}

internal class ScannerView: PrimerView {

    let navBar = UINavigationBar()
    let descriptionLabel = UILabel()
    let skipButton = UIButton()

    weak var scannerView: UIView?
    weak var delegate: ScannerViewDelegate?

    init(frame: CGRect, delegate: ScannerViewDelegate?, simpleScanView: UIView) {
        self.delegate = delegate
        self.scannerView = simpleScanView

        super.init(frame: frame)

        guard let scannerView = scannerView else { return }

        addSubview(scannerView)
        addSubview(navBar)
        addSubview(descriptionLabel)
        addSubview(skipButton)

        configureNavBar()
        configureDescriptionLabel()
        configureScannerView()
        configureSkipButton()

        anchorNavBar()
        setSkipButtonConstraints()
        anchorDescriptionLabel()
        setScannerViewConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: Configuration

internal extension ScannerView {
    private func configureNavBar() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        navBar.backgroundColor = theme.view.backgroundColor
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        backItem.tintColor = theme.text.system.color
        navItem.leftBarButtonItem = backItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = Content.ScannerView.Title
    }

    @objc private func cancel() { delegate?.cancel() }

    private func configureDescriptionLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        descriptionLabel.text = Content.ScannerView.DescriptionLabel
        descriptionLabel.textColor = theme.text.default.color
    }

    private func configureScannerView() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        scannerView?.clipsToBounds = true
        scannerView?.layer.cornerRadius = theme.mainButton.cornerRadius // ⚠️
    }

    private func configureSkipButton() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        skipButton.setTitle(Content.ScannerView.SkipButtonTitle, for: .normal)
        skipButton.setTitleColor(theme.text.system.color, for: .normal)
        skipButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }
}

// MARK: Anchoring

internal extension ScannerView {
    private func anchorNavBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    private func anchorDescriptionLabel() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 18).isActive = true
        descriptionLabel.leadingAnchor.constraint(
            equalTo: leadingAnchor,
            constant: theme.view.safeMargin
        ).isActive = true
        descriptionLabel.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -theme.view.safeMargin
        ).isActive = true
    }
    private func setScannerViewConstraints() {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        scannerView?.translatesAutoresizingMaskIntoConstraints = false
        scannerView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scannerView?.topAnchor.constraint(
            equalTo: descriptionLabel.bottomAnchor,
            constant: 20
        ).isActive = true
        scannerView?.widthAnchor.constraint(
            equalTo: widthAnchor,
            constant: -(theme.view.safeMargin * 2)
        ).isActive = true
        scannerView?.heightAnchor.constraint(
            equalTo: widthAnchor,
            multiplier: 0.55, constant: 1
        ).isActive = true
    }
    private func setSkipButtonConstraints() {
        guard let scannerView = scannerView else { return }
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.topAnchor.constraint(equalTo: scannerView.bottomAnchor, constant: 18).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
}

#endif

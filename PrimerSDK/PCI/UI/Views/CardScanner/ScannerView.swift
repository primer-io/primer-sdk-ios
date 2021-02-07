import UIKit
import CardScan //Bouncer

protocol ScannerViewDelegate: class {
    func cancel()
}

class ScannerView: UIView {
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

extension ScannerView {
    private func configureNavBar() {
        navBar.backgroundColor = Primer.theme.colorTheme.main1
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        backItem.tintColor = Primer.theme.colorTheme.tint1
        navItem.leftBarButtonItem = backItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = Primer.theme.content.scannerView.titleText
    }
    
    @objc private func cancel() { delegate?.cancel() }
    
    private func configureDescriptionLabel() {
        descriptionLabel.text = Primer.theme.content.scannerView.descriptionText
        descriptionLabel.textColor = Primer.theme.colorTheme.text1
    }
    
    private func configureScannerView() {
        scannerView?.clipsToBounds = true
        scannerView?.layer.cornerRadius = Primer.theme.cornerRadiusTheme.buttons //⚠️
    }
    
    private func configureSkipButton() {
        skipButton.setTitle(Primer.theme.content.scannerView.skipButtonText, for: .normal)
        skipButton.setTitleColor(Primer.theme.colorTheme.text3, for: .normal)
        skipButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }
}

// MARK: Anchoring

extension ScannerView {
    private func anchorNavBar() {
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.topAnchor.constraint(equalTo: topAnchor, constant: 6).isActive = true
        navBar.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    private func anchorDescriptionLabel() {
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.topAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 18).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Primer.theme.layout.safeMargin).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Primer.theme.layout.safeMargin).isActive = true
    }
    private func setScannerViewConstraints() {
        scannerView?.translatesAutoresizingMaskIntoConstraints = false
        scannerView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scannerView?.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20).isActive = true
        scannerView?.widthAnchor.constraint(equalTo: widthAnchor, constant: -(Primer.theme.layout.safeMargin * 2)).isActive = true
        scannerView?.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.55, constant: 1).isActive = true
    }
    private func setSkipButtonConstraints() {
        guard let scannerView = scannerView else { return }
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.topAnchor.constraint(equalTo: scannerView.bottomAnchor, constant: 18).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
}

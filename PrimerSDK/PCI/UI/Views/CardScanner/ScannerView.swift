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
    
    let theme: PrimerTheme
    
    init(frame: CGRect, theme: PrimerTheme, delegate: ScannerViewDelegate?, simpleScanView: UIView) {
        self.theme = theme
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
        navBar.backgroundColor = theme.backgroundColor
        let navItem = UINavigationItem()
        let backItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navItem.leftBarButtonItem = backItem
        navBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navBar.shadowImage = UIImage()
        navBar.setItems([navItem], animated: false)
        navBar.topItem?.title = theme.content.scannerView.titleText
    }
    @objc private func cancel() { delegate?.cancel() }
    private func configureDescriptionLabel() {
        descriptionLabel.text = theme.content.scannerView.descriptionText
        descriptionLabel.textColor = UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)
    }
    private func configureScannerView() {
        scannerView?.clipsToBounds = true
        scannerView?.layer.cornerRadius = theme.cornerRadiusTheme.buttons //⚠️
    }
    private func configureSkipButton() {
        skipButton.setTitle(theme.content.scannerView.skipButtonText, for: .normal)
        skipButton.setTitleColor(.systemBlue, for: .normal)
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
        descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
    }
    private func setScannerViewConstraints() {
        scannerView?.translatesAutoresizingMaskIntoConstraints = false
        scannerView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scannerView?.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 20).isActive = true
        scannerView?.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9, constant: 1).isActive = true
        scannerView?.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6, constant: 1).isActive = true
    }
    private func setSkipButtonConstraints() {
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
}

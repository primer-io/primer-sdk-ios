import UIKit
import CardScan //Bouncer

class ScannerView: UIView {
    
    var title = UILabel()
    var skipButton = UIButton()
    var scannerView = UIView()
    
    let theme: PrimerTheme
    
    init(frame: CGRect, theme: PrimerTheme) {
        self.theme = theme
        super.init(frame: frame)
        addSubview(title)
        addSubview(skipButton)
        configureTitle()
        configureSkipButton()
        setTitleConstraints()
        setSkipButtonConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addScanner(_ controller: SimpleScanViewController) {
        scannerView = controller.view!
        addSubview(scannerView)
        configureScannerView()
        setScannerViewConstraints()
    }
    
    private func configureTitle() {
        title.text = "Scan card"
        title.textColor = theme.fontColorTheme.title
        title.font = title.font.withSize(20)
    }
    
    private func configureSkipButton() {
        skipButton.setTitle("Manual input", for: .normal)
        skipButton.setTitleColor(.black, for: .normal)
    }
    
    private func configureScannerView() {
        scannerView.clipsToBounds = true
        scannerView.layer.cornerRadius = theme.cornerRadiusTheme.buttons
    }
    
    private func setTitleConstraints() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.topAnchor.constraint(equalTo: topAnchor, constant: 18).isActive = true
        title.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    private func setSkipButtonConstraints() {
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18).isActive = true
        skipButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
    
    private func setScannerViewConstraints() {
        scannerView.translatesAutoresizingMaskIntoConstraints = false
        scannerView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        scannerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        scannerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9, constant: 1).isActive = true
        scannerView.heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6, constant: 1).isActive = true
    }

}

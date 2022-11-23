//
//  CopyToClipboardButton.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 23/11/22.
//

#if canImport(UIKit)

class CopyToClipboardButton: UIButton {
    
    //MARK: - Properties
    
    var textToCopy: String? {
        didSet {
            setTitle(textToCopy, for: .normal)
        }
    }
    
    //MARK: - Initializers
    
    convenience init(textToCopy: String) {        
        self.init(type: .custom)
        self.setupView(textToCopy: textToCopy)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(copyToClipboardTapped(_ :)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addTarget(self, action: #selector(copyToClipboardTapped(_ :)), for: .touchUpInside)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension CopyToClipboardButton {
    
    //MARK: - Setup
    
    private func setupView(textToCopy: String) {
        self.textToCopy = textToCopy
        let copyToClipboardImage = UIImage(named: "copy-to-clipboard", in: Bundle.primerResources, compatibleWith: nil)
        let copiedToClipboardImage = UIImage(named: "check-circle", in: Bundle.primerResources, compatibleWith: nil)
        self.setImage(copyToClipboardImage, for: .normal)
        self.setImage(copiedToClipboardImage, for: .selected)
    }
}

extension CopyToClipboardButton {
    
    //MARK: - Action
    
    @objc
    internal func copyToClipboardTapped(_ sender: UIButton) {
        
        UIPasteboard.general.string = self.textToCopy
        
        log(logLevel: .debug, message: "📝📝📝📝 Copied: \(String(describing: UIPasteboard.general.string))")
        
        DispatchQueue.main.async {
            sender.isSelected = true
        }
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { timer in
            DispatchQueue.main.async {
                sender.isSelected = false
            }
            timer.invalidate()
        }
    }

}

#endif

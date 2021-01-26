import UIKit

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
    
    func addLine() {
        let lineView = UIView()
        lineView.backgroundColor = .systemBlue
        lineView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(lineView)
        lineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        lineView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        lineView.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -5).isActive = true
        lineView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 5).isActive = true
    }
    
    func toggleValidity(_ isValid: Bool, theme: PrimerTextFieldTheme) {
        if (isValid) {
            self.textColor = .black
            self.addIcon()
        } else {
            textColor = .red
            subviews.forEach { $0.removeFromSuperview() }
            switch theme {
            case .outlined:
                addOutlinedBorder(color: UIColor.systemRed.cgColor)
            case .underlined:
                addLineBorder(color: UIColor.systemRed)
            case .doublelined:
                addLineBorder(color: UIColor.systemRed, isTop: true)
                addLineBorder(color: UIColor.systemRed)
            }
            
        }
    }
    
    func addOutlinedBorder(color: CGColor) {
        let borderView = UIView()
        borderView.layer.zPosition = -1
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = color
        borderView.isUserInteractionEnabled = false
        addSubview(borderView)
        borderView.pin(to: self)
    }
    
    func addLineBorder(color: UIColor, isTop: Bool = false) {
        let lineView = UIView()
        lineView.backgroundColor = color
        self.addSubview(lineView)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        lineView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        lineView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        lineView.bottomAnchor.constraint(equalTo: isTop ? topAnchor : bottomAnchor).isActive = true
    }
    
    func addBorder(isFocused: Bool, title: String, cornerRadius: CGFloat, theme: PrimerTextFieldTheme) {
        
        self.subviews.forEach { $0.removeFromSuperview() }
        
        let color = isFocused ? UIColor.systemBlue : UIColor(red: 225/255, green: 222/255, blue: 218/255, alpha: 1)
        
        switch theme {
        case .outlined:
            addOutlinedBorder(color: UIColor.systemRed.cgColor)
        case .underlined:
            addLineBorder(color: color)
        case .doublelined:
            addLineBorder(color: color, isTop: true)
            addLineBorder(color: color)
        }
        
        if (isFocused && theme != .doublelined) {
            addFocusedTheme(title, theme: theme)
        }
        
    }
    
    func setBottomBorder(withColor color: UIColor) {
        self.borderStyle = UITextField.BorderStyle.none
        self.backgroundColor = UIColor.clear
        let width: CGFloat = 1.0
        let borderLine = UIView(frame: CGRect(x: 0, y: self.frame.height - width, width: self.frame.width, height: width))
        borderLine.backgroundColor = color
        self.addSubview(borderLine)
    }
    
    func addIcon() {
        let iconView = UIImageView(image: ImageName.check2.image)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(iconView)
//        iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        iconView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    func addMiniTitle(_ text: String) {
        let titleView = UILabel()
        titleView.text = text
        titleView.textColor = .white
        titleView.font = .systemFont(ofSize: 10, weight: .light)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleView)
        titleView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2).isActive = true
        titleView.topAnchor.constraint(equalTo: self.topAnchor, constant: -12).isActive = true
    }
    
    private func addFocusedTheme(_ text: String, theme: PrimerTextFieldTheme) {
        let titleView = UILabel()
        titleView.text = text
        titleView.textColor = .systemBlue
        titleView.font = .systemFont(ofSize: 10, weight: .light)
        titleView.backgroundColor = .white
        titleView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleView)
        titleView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: theme == .outlined ? 10 : 0).isActive = true
        titleView.topAnchor.constraint(equalTo: self.topAnchor, constant: -6).isActive = true
    }
}

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
}

enum TextFieldState {
    case `default`
    case valid
    case invalid
    
    func getColor(theme: PrimerThemeProtocol) -> UIColor {
        switch self {
        case .default:
            return theme.colorTheme.neutral1
        case .valid:
            return theme.colorTheme.tint1
        case .invalid:
            return theme.colorTheme.error1
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .default:
            return nil
        case .valid:
            let tintedIcon = ImageName.check2.image?.withRenderingMode(.alwaysTemplate)
            return tintedIcon
        case .invalid:
            let tintedIcon = ImageName.error.image?.withRenderingMode(.alwaysTemplate)
            return tintedIcon
        }
    }
}

class PrimerTextField: UITextField {
    
    var validationIsOptional = false
    
    var label = UILabel()
    var bottomBorder = CALayer()
    var underLine = UIView()
    var overLine = UIView()
    var errorMessage = UILabel()
    
    private var icon = UIImageView()
    
    @Dependency private(set) var theme: PrimerThemeProtocol
    
    var padding: CGFloat = 12
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        addSubview(errorMessage)
        addSubview(underLine)
        addSubview(overLine)
        
        setLeftPaddingPoints(padding)
        configureErrorMessage()
        configureLabel()
        
        switch theme.textFieldTheme {
        case .underlined:
            configureUnderLine()
        case .doublelined:
            configureOverLine()
            configureUnderLine()
        case .outlined:
            layer.borderWidth = 1
        }
        
        renderSubViews(validationState: .default)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func renderSubViews(validationState: TextFieldState, showIcon: Bool = true) {
        let color = validationState.getColor(theme: theme)
        
        // border
        switch theme.textFieldTheme {
        case .doublelined, .underlined:
            underLine.backgroundColor = color
            overLine.backgroundColor = color
        case .outlined:
            layer.borderColor = color.cgColor
            layer.cornerRadius = theme.cornerRadiusTheme.textFields
        }
        
        // label
        label.textColor = color
        
        // icon
        let image = validationState.icon
        let size = frame.size.height / 3
        let iconSize = validationState == .invalid ? size + 4 : size
        
        if !showIcon { return }
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.height, height: frame.size.height))
        icon.frame = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        icon.center = rightView!.center
        icon.image = image
        icon.tintColor = color
        rightViewMode = .unlessEditing
        rightView?.addSubview(icon)
    }
    
    private func configureLabel() {
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: topAnchor, constant: -2).isActive = true
    }
    
    private func configureUnderLine() {
        underLine.translatesAutoresizingMaskIntoConstraints = false
        underLine.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        underLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        underLine.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    private func configureOverLine() {
        overLine.translatesAutoresizingMaskIntoConstraints = false
        overLine.topAnchor.constraint(equalTo: topAnchor).isActive = true
        overLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        overLine.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }
    
    private func configureErrorMessage() {
        errorMessage.font = .systemFont(ofSize: 12)
        errorMessage.textColor = .systemRed
        errorMessage.translatesAutoresizingMaskIntoConstraints = false
        errorMessage.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        errorMessage.topAnchor.constraint(equalTo: bottomAnchor, constant: 2).isActive = true
    }
    
}

import UIKit

class PaymentMethodView: UIView {
    
    let title = UILabel()
    let firstButton = UIButton()
    let secondButton = UIButton()
    let thirdButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureTitle()
        configureButton(firstButton)
        configureButton(secondButton)
        configureButton(thirdButton)
        
        setTitleConstraints()
        setButtonConstraints(firstButton, top: title.bottomAnchor)
        setButtonConstraints(secondButton, top: firstButton.bottomAnchor)
        setButtonConstraints(thirdButton, top: secondButton.bottomAnchor)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureTitle() {
        addSubview(title)
        title.text = "£400"
        title.textColor = .black
        title.font = title.font.withSize(32)
    }
    
    func configureButton(_ btn: UIButton) {
        addSubview(btn)
        btn.backgroundColor = .gray
        btn.setTitle("pay", for: .normal)
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
    }
    
    func setTitleConstraints() {
        title.translatesAutoresizingMaskIntoConstraints = false
        title.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        title.heightAnchor.constraint(equalToConstant: 56).isActive = true
//        title.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24).isActive = true
        title.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24).isActive = true
    }
    
    func setButtonConstraints(_ btn: UIButton, top:  NSLayoutYAxisAnchor) {
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.topAnchor.constraint(equalTo: top, constant: 12).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        btn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24).isActive = true
        btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24).isActive = true
    }
    
}

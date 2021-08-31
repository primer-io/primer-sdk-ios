//
//  PrimerNavigationBar.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 31/8/21.
//

import UIKit

class PrimerNavigationBar: PrimerView {
    
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    internal var hidesBackButton: Bool = false {
        didSet {
            backButton.isHidden = hidesBackButton
        }
    }
    let horizontalStackView = UIStackView()
    let leftView = PrimerView()
    let mainView = PrimerView()
    let rightView = PrimerView()
    let backButton = UIButton()
    
    var rightBarButton: UIButton? {
        didSet {
            rightBarButton?.translatesAutoresizingMaskIntoConstraints = false
            rightBarButton?.tintColor = theme.colorTheme.tint1
            rightBarButton?.setTitleColor(theme.colorTheme.tint1, for: .normal)
            
            rightView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            
            if let rightBarButton = rightBarButton {
                rightView.addSubview(rightBarButton)
                
                if #available(iOS 11.0, *) {
                    rightBarButton.pin(view: self, leading: 0, top: 0, trailing: -12, bottom: 0)
                    rightBarButton.contentHorizontalAlignment = .trailing
                } else {
                    rightBarButton.topAnchor.constraint(equalTo: rightView.topAnchor, constant: 0).isActive = true
                    rightBarButton.bottomAnchor.constraint(equalTo: rightView.bottomAnchor, constant: 0).isActive = true
                    rightBarButton.leadingAnchor.constraint(greaterThanOrEqualTo: rightView.leadingAnchor).isActive = true
                    rightBarButton.trailingAnchor.constraint(equalTo: rightView.trailingAnchor, constant: 0).isActive = true
                }
                
                layoutIfNeeded()
            }
        }
    }
    
    var title: String? {
        didSet {
            titlelabel.text = title
        }
    }
    
    private var titlelabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func backButtonTapped(_ sender: Any) {
        Primer.shared.primerRootVC?.popViewController()
    }
    
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        backgroundColor = theme.colorTheme.main1
        
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(named: "back", in: Bundle.primerResources, compatibleWith: nil), for: .normal)
        backButton.tintColor = theme.colorTheme.tint1
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        leftView.addSubview(backButton)
        backButton.pin(view: leftView)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        backButton.isHidden = hidesBackButton
        
        addSubview(horizontalStackView)
        
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.pin(view: self, leading: 8.0, top: 0, trailing: -8.0, bottom: 0)
        horizontalStackView.alignment = .fill
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fill
        horizontalStackView.spacing = 8.0
        
        leftView.translatesAutoresizingMaskIntoConstraints = false
        leftView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        leftView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        leftView.backgroundColor = .clear
        horizontalStackView.addArrangedSubview(leftView)
        
        titlelabel.translatesAutoresizingMaskIntoConstraints = false
        titlelabel.backgroundColor = .clear
        titlelabel.textAlignment = .center
        titlelabel.textColor = theme.colorTheme.text1
        titlelabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        horizontalStackView.addArrangedSubview(titlelabel)
        
        rightView.translatesAutoresizingMaskIntoConstraints = false
        rightView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        rightView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        rightView.backgroundColor = .clear
        horizontalStackView.addArrangedSubview(rightView)
    }
    
}

//
//  PrimerCustomTextField.swift
//  PrimerSDK
//
//  Created by Boris on 25.3.24..
//

import UIKit

class PrimerCustomFieldView: UIView {

    var fieldView: PrimerTextFieldView!
    override var tintColor: UIColor! {
        didSet {
            topPlaceholderLabel.textColor = tintColor
            bottomLine.backgroundColor = tintColor
        }
    }
    var placeholderText: String?
    var rightImage1: UIImage? {
        didSet {
            rightImageView1Container.isHidden = rightImage1 == nil
            rightImageView1.image = rightImage1
        }
    }
    var rightImage1TintColor: UIColor? {
        didSet {
            rightImageView1.tintColor = rightImage1TintColor
        }
    }
    var rightImage2: UIImage? {
        didSet {
            rightImageView2.isHidden = rightImage2 == nil
            rightImageView2.image = rightImage2
        }
    }
    var rightImage2TintColor: UIColor? {
        didSet {
            rightImageView2.tintColor = rightImage2TintColor
        }
    }
    var errorText: String? {
        didSet {
            errorLabel.text = errorText ?? ""
        }
    }

    private var verticalStackView: UIStackView = UIStackView()
    private let errorLabel = UILabel()
    private let topPlaceholderLabel = UILabel()
    private let rightImageView1Container = UIView()
    private let rightImageView1 = UIImageView()   // As in the one furthest right
    private let rightImageView2Container = UIView()
    private let rightImageView2 = UIImageView()
    private let bottomLine = UIView()
    private var theme: PrimerThemeProtocol = DependencyContainer.resolve()

    func setup() {
        setupVerticalStackView()
        setupTopPlaceholderLabel()
        setupTextFieldStackView()
        setupBottomLine()
        setupErrorLabel()
        constrainVerticalStackView()
    }

    private func setupVerticalStackView() {
        addSubview(verticalStackView)
        verticalStackView.alignment = .fill
        verticalStackView.axis = .vertical
    }

    private func setupTopPlaceholderLabel() {
        topPlaceholderLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        topPlaceholderLabel.text = placeholderText
        topPlaceholderLabel.textColor = theme.text.system.color
        verticalStackView.addArrangedSubview(topPlaceholderLabel)
    }

    private func setupTextFieldStackView() {
        let textFieldStackView = createTextFieldStackView()

        setupRightImageView2Container(in: textFieldStackView)
        setupRightImageView1Container(in: textFieldStackView)

        verticalStackView.addArrangedSubview(textFieldStackView)
    }

    private func createTextFieldStackView() -> UIStackView {
        let textFieldStackView = UIStackView()
        textFieldStackView.alignment = .fill
        textFieldStackView.axis = .horizontal
        textFieldStackView.addArrangedSubview(fieldView)
        textFieldStackView.spacing = 6
        return textFieldStackView
    }

    private func setupRightImageView2Container(in stackView: UIStackView) {
        rightImageView2.contentMode = .scaleAspectFit

        stackView.addArrangedSubview(rightImageView2Container)
        rightImageView2Container.translatesAutoresizingMaskIntoConstraints = false
        rightImageView2Container.addSubview(rightImageView2)
        rightImageView2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightImageView2.topAnchor.constraint(equalTo: rightImageView2Container.topAnchor, constant: 6),
            rightImageView2.bottomAnchor.constraint(equalTo: rightImageView2Container.bottomAnchor, constant: -6),
            rightImageView2.leadingAnchor.constraint(equalTo: rightImageView2Container.leadingAnchor),
            rightImageView2.trailingAnchor.constraint(equalTo: rightImageView2Container.trailingAnchor),
            rightImageView2.widthAnchor.constraint(equalTo: rightImageView2Container.heightAnchor)
        ])
    }

    private func setupRightImageView1Container(in stackView: UIStackView) {
        rightImageView1.contentMode = .scaleAspectFit

        stackView.addArrangedSubview(rightImageView1Container)
        rightImageView1Container.translatesAutoresizingMaskIntoConstraints = false
        rightImageView1Container.addSubview(rightImageView1)
        rightImageView1.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightImageView1.topAnchor.constraint(equalTo: rightImageView1Container.topAnchor, constant: 10),
            rightImageView1.bottomAnchor.constraint(equalTo: rightImageView1Container.bottomAnchor, constant: -10),
            rightImageView1.leadingAnchor.constraint(equalTo: rightImageView1Container.leadingAnchor),
            rightImageView1.trailingAnchor.constraint(equalTo: rightImageView1Container.trailingAnchor),
            rightImageView1.widthAnchor.constraint(equalTo: rightImageView1Container.heightAnchor)
        ])
    }

    private func setupBottomLine() {
        bottomLine.backgroundColor = theme.colors.primary
        bottomLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        verticalStackView.addArrangedSubview(bottomLine)
    }

    private func setupErrorLabel() {
        errorLabel.textColor = theme.text.error.color
        errorLabel.heightAnchor.constraint(equalToConstant: 12.0).isActive = true
        errorLabel.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        errorLabel.text = nil
        verticalStackView.addArrangedSubview(errorLabel)
    }

    private func constrainVerticalStackView() {
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: topAnchor),
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

//
//  ErrorViewController.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 13/01/2021.
//

#if canImport(UIKit)

import UIKit

internal class ErrorViewController: PrimerViewController {

    var rightBarButton: UIBarButtonItem!
    let icon = UIImageView(image: ImageName.error.image?.withRenderingMode(.alwaysTemplate))
    let message = UILabel()

    init(message: String) {
        super.init(nibName: nil, bundle: nil)
        self.message.text = message
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        (parent as? PrimerContainerViewController)?.navigationItem.hidesBackButton = true

        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        rightBarButton = UIBarButtonItem(
            title: "Done",
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(close)
        )
        rightBarButton.tintColor = theme.text.system.color
        icon.tintColor = theme.text.error.color
        icon.contentMode = .scaleAspectFit

        view.addSubview(icon)
        view.addSubview(message)

        configureMessage()

        anchorIcon()
        anchorMessage()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (parent as? PrimerContainerViewController)?.navigationItem.hidesBackButton = true
        (parent as? PrimerContainerViewController)?.navigationItem.rightBarButtonItem = rightBarButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (parent as? PrimerContainerViewController)?.navigationItem.hidesBackButton = true
        (parent as? PrimerContainerViewController)?.navigationItem.rightBarButtonItem = rightBarButton
    }

    @objc func close() {
        Primer.shared.dismiss()
    }

}

internal extension ErrorViewController {

    func configureMessage() {
        if !message.text.exists {
            message.text = NSLocalizedString("primer-error-screen-message",
                                             tableName: nil,
                                             bundle: Bundle.primerResources,
                                             value: "Your payment method couldn't\nbe added. Please try again.",
                                             comment: "Your payment method couldn't\nbe added. Please try again. - Primer error screen message")
        }
        message.numberOfLines = 0
        message.textAlignment = .center
        message.font = .systemFont(ofSize: 20)
    }
}

internal extension ErrorViewController {

    func anchorIcon() {
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30).isActive = true
        icon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 40).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    func anchorMessage() {
        message.translatesAutoresizingMaskIntoConstraints = false
        message.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12).isActive = true
        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
    }

}

#endif

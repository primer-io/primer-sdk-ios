//
//  PrimerResultViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 3/2/22.
//

import UIKit

final class PrimerResultViewController: PrimerViewController {
    enum ScreenType {
        case success, failure
    }

    private(set) var message: String?
    private(set) var screenType: ScreenType
    private(set) var resultView: PrimerResultComponentView!

    init(screenType: PrimerResultViewController.ScreenType, message: String?) {
        self.message = message
        self.screenType = screenType
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        postUIEvent(.view, type: .view, in: .errorScreen)
        (parent as? PrimerContainerViewController)?.navigationItem.hidesBackButton = true

        let successImage: UIImage? = .checkCircle
        successImage?.accessibilityIdentifier = "check-circle"

        let failureImage: UIImage? = .xCircle
        failureImage?.accessibilityIdentifier = "x-circle"

        let img = (screenType == .success) ? successImage : failureImage
        let imgView = UIImageView(image: img?.withRenderingMode(.alwaysTemplate))
        imgView.contentMode = .scaleAspectFit
        imgView.tintColor = .label
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: 20.0).isActive = true
        imgView.accessibilityIdentifier = img?.accessibilityIdentifier

        resultView = PrimerResultComponentView(frame: .zero, imageView: imgView, message: message, loadingIndicator: nil)
        view.addSubview(resultView)
        resultView.translatesAutoresizingMaskIntoConstraints = false
        resultView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        resultView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        resultView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        resultView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (parent as? PrimerContainerViewController)?.navigationItem.hidesBackButton = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (parent as? PrimerContainerViewController)?.navigationItem.hidesBackButton = true
    }
}

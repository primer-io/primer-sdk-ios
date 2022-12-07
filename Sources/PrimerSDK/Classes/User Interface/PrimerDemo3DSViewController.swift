//
//  PrimerDemo3DSViewController.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/12/22.
//

#if canImport(UIKit)

import UIKit

class PrimerDemo3DSViewController: UIViewController {
    
    var demo3DSLabel = UILabel()
    var scenarioLabel = UILabel()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        demo3DSLabel.text = "Demo 3DS"
        demo3DSLabel.font = UIFont.systemFont(ofSize: 30, weight: .heavy)
        view.addSubview(demo3DSLabel)
        demo3DSLabel.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            demo3DSLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        } else {
            demo3DSLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
        }
        demo3DSLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        scenarioLabel.text = "Pass Challenge"
        scenarioLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        view.addSubview(scenarioLabel)
        scenarioLabel.translatesAutoresizingMaskIntoConstraints = false
        scenarioLabel.topAnchor.constraint(equalTo: demo3DSLabel.bottomAnchor, constant: 20).isActive = true
        scenarioLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
}

#endif

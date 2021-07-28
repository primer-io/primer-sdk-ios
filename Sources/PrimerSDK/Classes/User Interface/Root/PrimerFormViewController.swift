//
//  PrimerFormViewController.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 27/7/21.
//

import UIKit

class PrimerFormViewController: UIViewController {

    @IBOutlet weak var verticalStackView: UIStackView!
    
    class func instantiate() -> PrimerFormViewController {
        let bundle = Bundle.primerFramework
        let storyboard = UIStoryboard(name: "Primer", bundle: bundle)
        let pfvc = storyboard.instantiateViewController(withIdentifier: "PrimerFormViewController") as! PrimerFormViewController
        return pfvc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let testView1 = UIView()
        testView1.backgroundColor = .red
        testView1.heightAnchor.constraint(equalToConstant: 100).isActive = true
        verticalStackView.addArrangedSubview(testView1)
        
        let testView2 = UIView()
        testView2.backgroundColor = .green
        testView2.heightAnchor.constraint(equalToConstant: 200).isActive = true
        verticalStackView.addArrangedSubview(testView2)
        
        let testView3 = UIView()
        testView3.backgroundColor = .black
        testView3.heightAnchor.constraint(equalToConstant: 2000).isActive = true
        verticalStackView.addArrangedSubview(testView3)
        
        view.layoutIfNeeded()
        print("")
    }
    
}

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
    }
    
}

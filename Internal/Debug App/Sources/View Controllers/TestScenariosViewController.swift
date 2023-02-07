//
//  TestScenariosViewController.swift
//  Debug App
//
//  Created by Evangelos Pittas on 26/1/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit

class TestScenariosViewController: UIViewController {
    
    class func instantiate() -> TestScenariosViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TestScenariosViewController") as! TestScenariosViewController
        return vc
    }
    
    let dataSource = Test.Scenario.allCases
    var selectedTestScenario: Test.Scenario?
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension TestScenariosViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let testScenario = self.dataSource[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestScenarioCell", for: indexPath) as! TestScenarioCell
        cell.configure(testScenario: testScenario)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let testScenario = self.dataSource[indexPath.row]
        let vc = TestParametersViewController.instantiate(testScenario: testScenario)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

class TestScenarioCell: UITableViewCell {
    
    var testScenario: Test.Scenario!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func prepareForReuse() {
        self.titleLabel.text = nil
    }
    
    func configure(testScenario: Test.Scenario) {
        self.testScenario = testScenario
        self.titleLabel.text = testScenario.rawValue
    }
}

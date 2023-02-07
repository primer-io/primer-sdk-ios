//
//  TestParametersViewController.swift
//  Debug App
//
//  Created by Evangelos Pittas on 26/1/23.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import UIKit

class TestParametersViewController: UIViewController {
    
    class func instantiate(testScenario: Test.Scenario) -> TestParametersViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TestParametersViewController") as! TestParametersViewController
        vc.testScenario = testScenario
        return vc
    }
    
    var testScenario: Test.Scenario!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var resultSegmentedControl: UISegmentedControl!
    @IBOutlet weak var failureParametersStackView: UIStackView!
    @IBOutlet weak var networkParametersStackView: UIStackView!
    @IBOutlet weak var pollingParametersStackView: UIStackView!
    @IBOutlet weak var threeDSParametersStackView: UIStackView!
    @IBOutlet weak var selectFailureFlowTextField: UITextField!
    @IBOutlet weak var errorIdTextField: UITextField!
    @IBOutlet weak var errorDescriptionTextField: UITextField!
    @IBOutlet weak var latencyTextField: UITextField!
    @IBOutlet weak var pollingIterationsTextField: UITextField!
    @IBOutlet weak var threeDSScenarioTextField: UITextField!
    
    let failureFlowPicker = UIPickerView()
    let failureFlowsDataSource = Test.Flow.allCases
    let threeDSScenarioPicker = UIPickerView()
    let threeDSScenariosDataSource = Test.Params.ThreeDS.Scenario.allCases
    
    var testParams: Test.Params!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.testParams = Test.Params(
            scenario: self.testScenario,
            result: .success,
            network: nil,
            polling: nil,
            threeDS: nil)
                
        self.failureFlowPicker.dataSource = self
        self.failureFlowPicker.delegate = self
        self.selectFailureFlowTextField.inputView = self.failureFlowPicker
        
        self.threeDSScenarioPicker.dataSource = self
        self.threeDSScenarioPicker.delegate = self
        self.threeDSScenarioTextField.inputView = self.threeDSScenarioPicker
        
        self.render()
    }
    
    func render() {
        if self.resultSegmentedControl.selectedSegmentIndex == 1 {
            self.failureParametersStackView.isHidden = false
            self.networkParametersStackView.isHidden = true
            self.pollingParametersStackView.isHidden = true
            self.threeDSParametersStackView.isHidden = true
            
        } else {
            self.failureParametersStackView.isHidden = true
            
            if self.testScenario != .testNative3DS {
                self.threeDSParametersStackView.isHidden = true
            }
            
            switch testScenario {
            case .testAdyenGiropay,
                    .testAdyenBlik:
                self.pollingParametersStackView.isHidden = false
            default:
                self.pollingParametersStackView.isHidden = true
            }
        }
    }
    
    @IBAction func viewTapped(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    @IBAction func resultSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        self.render()
    }
    
    @IBAction func primerSDKButtonTapped(_ sender: Any) {
        if self.resultSegmentedControl.selectedSegmentIndex == 0 {
            self.testParams.result = .success
            
            if let latencyText = self.latencyTextField.text,
               let latency = Int(latencyText) {
                self.testParams.network = Test.Params.Network(delay: latency)
            }
            
            if let threeDSText = self.threeDSScenarioTextField.text,
               let threeDSScenario = Test.Params.ThreeDS.Scenario(rawValue: threeDSText) {
                self.testParams.threeDS = Test.Params.ThreeDS(scenario: threeDSScenario)
            }
            
            if let pollingIterationsText = self.pollingIterationsTextField.text,
               let pollingIterations = Int(pollingIterationsText) {
                self.testParams.polling = Test.Params.Polling(iterations: pollingIterations)
            }
            
        } else {
            if let failureFlowText = self.selectFailureFlowTextField.text,
               let failureFlow = Test.Flow(rawValue: failureFlowText),
               let errorId = errorIdTextField.text,
               let errorDescription = errorDescriptionTextField.text
            {
                let failure = Test.Params.Failure(
                    flow: failureFlow,
                    error: Test.Params.Failure.Error(
                        errorId: errorId,
                        description: errorDescription))
                self.testParams.result = .failure(failure: failure)
            } else {
                fatalError()
            }
        }
        
        clientSessionRequestBody.testParams = testParams
    
        let vc = MerchantCheckoutViewController.instantiate()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension TestParametersViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == self.failureFlowPicker {
            return self.failureFlowsDataSource.count
        } else if pickerView == self.threeDSScenarioPicker {
            return self.threeDSScenariosDataSource.count
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == self.failureFlowPicker {
            return self.failureFlowsDataSource[row].rawValue
        } else if pickerView == self.threeDSScenarioPicker {
            return self.threeDSScenariosDataSource[row].rawValue
        }
        
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == self.failureFlowPicker {
            self.selectFailureFlowTextField.text = self.failureFlowsDataSource[row].rawValue
        } else if pickerView == self.threeDSScenarioPicker {
            self.threeDSScenarioTextField.text = self.threeDSScenariosDataSource[row].rawValue
        }
    }
}

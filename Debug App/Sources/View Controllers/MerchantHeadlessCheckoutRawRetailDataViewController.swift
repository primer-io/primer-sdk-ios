//
//  MerchantHUCRawCardDataViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 12/7/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

class MerchantHeadlessCheckoutRawRetailDataViewController: UIViewController {

    static func instantiate(paymentMethodType: String) -> MerchantHeadlessCheckoutRawRetailDataViewController {
        let mpmvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MerchantHUCRawRetailDataViewController") as! MerchantHeadlessCheckoutRawRetailDataViewController
        mpmvc.paymentMethodType = paymentMethodType
        return mpmvc
    }

    var paymentMethodType: String!
    var paymentId: String?
    var activityIndicator: UIActivityIndicatorView?
    var rawData: PrimerRawData?
    private let cellIdentifier = "RetailDataTableViewCell"

    internal lazy var tableView: UITableView = {

        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.rowHeight = 56
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    var selectedOutletIdentifier: String!
    var selectedIndexPath: IndexPath?
    var payButton: UIButton!
    var retailers: [RetailOutletsRetail] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    var logs: [String] = []
    var primerRawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(tableView)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        self.tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true

        self.payButton = UIButton(frame: .zero)

        self.payButton.accessibilityIdentifier = "submit_btn"
        self.payButton.setTitle("Issue voucher", for: .normal)
        self.payButton.titleLabel?.adjustsFontSizeToFitWidth = true
        self.payButton.titleLabel?.minimumScaleFactor = 0.7
        self.payButton.backgroundColor = .black
        self.payButton.setTitleColor(.white, for: .normal)
        self.payButton.addTarget(self, action: #selector(issueVoucherButtonTapped), for: .touchUpInside)
        self.tableView.tableFooterView = self.payButton
        self.tableView.tableFooterView?.frame.size.height = 45

        do {
            self.showLoadingOverlay()
            self.primerRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: self.paymentMethodType)
            primerRawDataManager.delegate = self
            primerRawDataManager.configure { [weak self] data, error in
                guard error == nil else {
                    self?.hideLoadingOverlay()
                    return
                }
                self?.retailers = (data as? RetailOutletsList)?.result ?? []
                self?.hideLoadingOverlay()
            }
        } catch {

        }
    }

    @IBAction func issueVoucherButtonTapped(_ sender: UIButton) {
        if paymentMethodType == "XENDIT_RETAIL_OUTLETS" {
            self.rawData = PrimerRetailerData(id: selectedOutletIdentifier)
            primerRawDataManager.rawData = self.rawData!
            primerRawDataManager.submit()
            self.showLoadingOverlay()
        }
    }

    // MARK: - HELPERS

    private func showLoadingOverlay() {
        DispatchQueue.main.async {
            if self.activityIndicator == nil {
                self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
                self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
                self.activityIndicator?.color = .black
                self.view.addSubview(self.activityIndicator!)
            }
            self.activityIndicator?.startAnimating()
        }
    }

    private func hideLoadingOverlay() {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.removeFromSuperview()
            self.activityIndicator = nil
        }
    }
}

extension MerchantHeadlessCheckoutRawRetailDataViewController: UITableViewDataSource, UITableViewDelegate {

    // MARK: - Table View delegate methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedIndexPath != nil {
            self.tableView.cellForRow(at: selectedIndexPath!)?.accessoryType = .none
        }
        selectedIndexPath = indexPath
        self.tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        let retailer = retailers[indexPath.row]
        selectedOutletIdentifier = retailer.id
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select a retailer"
    }

    // MARK: - Table View data source methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return retailers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let retailer = retailers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        tableView.cellForRow(at: indexPath)?.accessoryType = selectedIndexPath == indexPath ? .checkmark : .none
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = retailer.name
            cell.contentConfiguration = content
        } else {
            // Fallback on earlier versions
        }

        return cell
    }
}

extension MerchantHeadlessCheckoutRawRetailDataViewController: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        print("\n\nMERCHANT APP\n\(#function)\ndataIsValid: \(isValid)")
        self.logs.append(#function)
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?) {
        print("\n\nMERCHANT APP\n\(#function)\nmetadataDidChange: \(String(describing: metadata))")
        self.logs.append(#function)
    }
}

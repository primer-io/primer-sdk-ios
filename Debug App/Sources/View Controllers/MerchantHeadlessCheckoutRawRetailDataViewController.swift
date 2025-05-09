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
        tableView.contentInsetAdjustmentBehavior = .never
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
            tableView.reloadData()
        }
    }

    var logs: [String] = []
    var primerRawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true

        payButton = UIButton(frame: .zero)

        payButton.accessibilityIdentifier = "submit_btn"
        payButton.setTitle("Issue voucher", for: .normal)
        payButton.titleLabel?.adjustsFontSizeToFitWidth = true
        payButton.titleLabel?.minimumScaleFactor = 0.7
        payButton.backgroundColor = .black
        payButton.setTitleColor(.white, for: .normal)
        payButton.addTarget(self, action: #selector(issueVoucherButtonTapped), for: .touchUpInside)
        tableView.tableFooterView = payButton
        tableView.tableFooterView?.frame.size.height = 45

        do {
            showLoadingOverlay()
            primerRawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(paymentMethodType: paymentMethodType)
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
            rawData = PrimerRetailerData(id: selectedOutletIdentifier)
            primerRawDataManager.rawData = rawData!
            primerRawDataManager.submit()
            showLoadingOverlay()
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
            cell.textLabel?.text = retailer.name
        }

        return cell
    }
}

extension MerchantHeadlessCheckoutRawRetailDataViewController: PrimerHeadlessUniversalCheckoutRawDataManagerDelegate {

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, dataIsValid isValid: Bool, errors: [Error]?) {
        print("\n\nMERCHANT APP\n\(#function)\ndataIsValid: \(isValid)")
        logs.append(#function)
    }

    func primerRawDataManager(_ rawDataManager: PrimerHeadlessUniversalCheckout.RawDataManager, metadataDidChange metadata: [String: Any]?) {
        print("\n\nMERCHANT APP\n\(#function)\nmetadataDidChange: \(String(describing: metadata))")
        logs.append(#function)
    }
}

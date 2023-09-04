//
//  MerchantAssetsViewController.swift
//  PrimerSDK_Example
//
//  Created by Evangelos on 7/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import PrimerSDK
import UIKit

fileprivate enum PrimerPaymentMethodTypeForAssets: String, CaseIterable, Equatable, Hashable {
    
    case adyenAlipay            = "ADYEN_ALIPAY"
    case adyenBlik              = "ADYEN_BLIK"
    case adyenBancontactCard    = "ADYEN_BANCONTACT_CARD"
    case adyenDotPay            = "ADYEN_DOTPAY"
    case adyenGiropay           = "ADYEN_GIROPAY"
    case adyenIDeal             = "ADYEN_IDEAL"
    case adyenInterac           = "ADYEN_INTERAC"
    case adyenMobilePay         = "ADYEN_MOBILEPAY"
    case adyenMBWay             = "ADYEN_MBWAY"
    case adyenMultibanco        = "ADYEN_MULTIBANCO"
    case adyenPayTrail          = "ADYEN_PAYTRAIL"
    case adyenPayshop           = "ADYEN_PAYSHOP"
    case adyenSofort            = "ADYEN_SOFORT"
    case adyenTrustly           = "ADYEN_TRUSTLY"
    case adyenTwint             = "ADYEN_TWINT"
    case adyenVipps             = "ADYEN_VIPPS"
    case apaya                  = "APAYA"
    case applePay               = "APPLE_PAY"
    case atome                  = "ATOME"
    case buckarooBancontact     = "BUCKAROO_BANCONTACT"
    case buckarooEps            = "BUCKAROO_EPS"
    case buckarooGiropay        = "BUCKAROO_GIROPAY"
    case buckarooIdeal          = "BUCKAROO_IDEAL"
    case buckarooSofort         = "BUCKAROO_SOFORT"
    case coinbase               = "COINBASE"
    case goCardless             = "GOCARDLESS"
    case googlePay              = "GOOGLE_PAY"
    case hoolah                 = "HOOLAH"
    case iPay88Card             = "IPAY88_CARD"
    case klarna                 = "KLARNA"
    case mollieBankcontact      = "MOLLIE_BANCONTACT"
    case mollieIdeal            = "MOLLIE_IDEAL"
    case opennode               = "OPENNODE"
    case payNLBancontact        = "PAY_NL_BANCONTACT"
    case payNLGiropay           = "PAY_NL_GIROPAY"
    case payNLIdeal             = "PAY_NL_IDEAL"
    case payNLPayconiq          = "PAY_NL_PAYCONIQ"
    case paymentCard            = "PAYMENT_CARD"
    case payPal                 = "PAYPAL"
    case primerTestKlarna       = "PRIMER_TEST_KLARNA"
    case primerTestPayPal       = "PRIMER_TEST_PAYPAL"
    case primerTestSofort       = "PRIMER_TEST_SOFORT"
    case rapydFast              = "RAPYD_FAST"
    case rapydGCash             = "RAPYD_GCASH"
    case rapydGrabPay           = "RAPYD_GRABPAY"
    case rapydPromptPay         = "RAPYD_PROMPTPAY"
    case rapydPoli              = "RAPYD_POLI"
    case omisePromptPay         = "OMISE_PROMPTPAY"
    case twoCtwoP               = "TWOC2P"
    case xenditOvo              = "XENDIT_OVO"
    case xenditRetailOutlets    = "XENDIT_RETAIL_OUTLETS"
    case xfersPayNow            = "XFERS_PAYNOW"
}

fileprivate extension PrimerPaymentMethodLogo {
    var preferred: UIImage? {
        return colored ?? light ?? dark
    }
    
    func forSelectedType(value: Int) -> UIImage? {
        switch value {
        case 0: return colored
        case 1: return light
        case 2: return dark
        default: return preferred
        }
    }
}

class MerchantAssetsViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var assets: [(name: String, image: UIImage?)] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var assetType: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .lightGray
        self.collectionView.backgroundColor = .clear
        
        let clientSessionRequestBody = Networking().clientSessionRequestBodyWithCurrency(String.randomString(length: 8),
                                                                                     phoneNumber: "",
                                                                                     countryCode: .gb,
                                                                                     currency: .USD,
                                                                                     amount: 101)

        Networking.requestClientSession(requestBody: clientSessionRequestBody) { (clientToken, err) in
            if let err = err {
                print(err)
                let merchantErr = NSError(domain: "merchant-domain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch client token"])
                print(merchantErr)
            } else if let clientToken = clientToken {
                let settings = PrimerSettings(
                    paymentHandling: paymentHandling == .auto ? .auto : .manual,
                    paymentMethodOptions: PrimerPaymentMethodOptions(
                        urlScheme: "merchant://redirect",
                        applePayOptions: PrimerApplePayOptions(merchantIdentifier: "merchant.dx.team", merchantName: "Primer Merchant")
                    )
                )
                                
                PrimerHeadlessUniversalCheckout.current.start(withClientToken: clientToken, settings: settings, completion: { (pms, err) in
                    self.reloadImages()
                })
            }
        }
    }
    
    func reloadImages(selected: Int = 0) {
        var tmpAssets: [(name: String, image: UIImage?)] = []
        let assets = PrimerPaymentMethodTypeForAssets.allCases
        for assetName in assets {
            do {
                guard let asset = try PrimerHeadlessUniversalCheckout.AssetsManager.getPaymentMethodAsset(for: assetName.rawValue) else {
                    print("\n\n⚠️ failed to find asset for name: \(assetName.rawValue)")
                    continue
                }
                tmpAssets.append((asset.paymentMethodName, asset.paymentMethodLogo.forSelectedType(value: selected)))
            } catch let error {
                print("\n\n🚨 Failed to load image asset: \(error.localizedDescription)")
            }
        }
        self.assets = tmpAssets
    }
    
    @IBAction func assetTypeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        self.reloadImages(selected: sender.selectedSegmentIndex)
    }
}

extension MerchantAssetsViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MerchantAssetCell", for: indexPath) as! MerchantAssetCell
        let asset = assets[indexPath.row]
        cell.configure(asset: asset)
        return cell
    }
    
    
}

class MerchantAssetCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func configure(asset: (name: String, image: UIImage?)) {
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.image = asset.image
        self.titleLabel.text = asset.name
    }
    
}

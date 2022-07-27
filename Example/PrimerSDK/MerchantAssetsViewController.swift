//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

import PrimerSDK
import UIKit

class MerchantAssetsViewController: UIViewController {
    
    @IBOutlet weak var imageTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var colorTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    var assets: [(name: String, image: UIImage?)] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    var assetType: PrimerAsset.ImageType = .logo {
        didSet {
            self.reloadImages()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadImages()
    }
    
    func reloadImages() {
        var tmpAssets: [(name: String, image: UIImage?)] = []
        let brands = PrimerAsset.Brand.allCases
        for brand in brands {
            tmpAssets.append((brand.rawValue, PrimerHeadlessUniversalCheckout.getAsset(for: brand, assetType: self.assetType)))
        }
        self.assets = tmpAssets
    }
    
    @IBAction func segmentedControlerValueChanged(_ sender: UISegmentedControl) {
        if imageTypeSegmentedControl == sender {
            self.assetType = sender.selectedSegmentIndex == 1 ? .icon : .logo
        }
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
        self.imageView.image = asset.image
        self.titleLabel.text = asset.name
    }
    
}

//
//  ImageName.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 29/12/2020.
//

import UIKit

enum ImageName: String {
  case
  amex,
  discover,
  mastercard,
  visa,
  unknownCard
  
  var image: UIImage? {
    guard let image = UIImage(named: rawValue) else {
      return nil
    }
    
    return image
  }
}

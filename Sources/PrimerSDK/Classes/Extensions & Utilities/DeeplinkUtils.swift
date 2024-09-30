//
//  DeeplinkUtils.swift
//  Pods
//
//  Created by Niall Quinn on 30/09/24.
//

import Foundation
import UIKit

protocol DeeplinkAbilityProviding {
    func canOpenURL(_ url: URL) -> Bool
}

extension UIApplication: DeeplinkAbilityProviding {}

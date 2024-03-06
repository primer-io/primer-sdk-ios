//
//  NativeUIPresentable.swift
//  PrimerSDK
//
//  Created by Niall Quinn on 27/02/24.
//

import Foundation

protocol NativeUIPresentable {
    func present(intent: PrimerSessionIntent,
                 clientToken: String)
}

//
//  PrimerIntegrationOptions.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/11/22.
//



import Foundation

public class PrimerIntegrationOptions: NSObject {
    
    var reactNativeVersion: String?
    
    public init(reactNativeVersion: String?) {
        self.reactNativeVersion = reactNativeVersion
    }
}



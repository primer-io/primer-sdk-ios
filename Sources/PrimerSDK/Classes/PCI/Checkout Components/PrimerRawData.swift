//
//  PrimerRawData.swift
//  PrimerSDK
//
//  Created by Evangelos on 12/7/22.
//



import Foundation

internal protocol PrimerRawDataProtocol: Encodable {
    var onDataDidChange: (() -> Void)? { get set }
}

public class PrimerRawData: NSObject, PrimerRawDataProtocol {
    
    var onDataDidChange: (() -> Void)?
    
    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}



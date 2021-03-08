//
//  String+Extensions.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 07/03/2021.
//
extension String {
    var withoutWhiteSpace: String {
        return self.filter { !$0.isWhitespace }
    }
    
    var isNotValidIBAN: Bool {
        return self.withoutWhiteSpace.count < 6
    }
}

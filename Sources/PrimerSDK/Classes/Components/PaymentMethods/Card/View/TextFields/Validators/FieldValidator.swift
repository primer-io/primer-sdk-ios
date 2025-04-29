//
//  FieldValidator.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import Foundation

public protocol FieldValidator {
    func validateWhileTyping(_ input: String) -> ValidationResult
    func validateOnCommit(_ input: String) -> ValidationResult
}
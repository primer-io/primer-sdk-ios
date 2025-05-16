//
//  ValidationCoordinator.swift
//
//
//  Created by Boris on 26.3.25..
//

import Foundation

/// Coordinates validation timing and feedback for input fields
protocol ValidationCoordinator {
    associatedtype InputType

    var validationService: ValidationService { get }
    var onValidationChange: ((Bool) -> Void)? { get }
    var onErrorMessageChange: ((String?) -> Void)? { get }

    /// Light validation during typing - typically less strict
    func validateWhileTyping(_ input: InputType) -> ValidationResult

    /// Full validation when field loses focus - typically shows errors
    func validateOnBlur(_ input: InputType) -> ValidationResult
}

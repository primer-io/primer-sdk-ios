//
//  String+Extension.swift
//
//
//  Created by Boris on 26.3.25..
//

// Helper extensions
extension String {
    func inserting(contentsOf string: String, at index: String.Index) -> String {
        var result = self
        result.insert(contentsOf: string, at: index)
        return result
    }

    func removing(at index: String.Index) -> String {
        var result = self
        result.remove(at: index)
        return result
    }
}

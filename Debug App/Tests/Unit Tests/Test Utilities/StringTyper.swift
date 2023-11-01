//
//  StringTyper.swift
//  Debug App
//
//  Created by Jack Newcombe on 01/11/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation

class StringTyper {
    let receiver: (String) -> Void
    
    let queue: DispatchQueue
    
    /// - Parameter receiver: The receiver to send results to
    init(_ receiver: @escaping (String) -> Void, queue: DispatchQueue = .main) {
        self.receiver = receiver
        self.queue = queue
    }
    
    /// Simulate typing output to a string
    ///
    /// For example, for the string "test", the following will be sent to the receiver with a delay of `delay` seconds:
    ///  - t
    ///  - te
    ///  - tes
    ///  - test
    ///
    /// - Parameters:
    ///   - string: The string that should be types
    ///   - result: The string that is being written to (do not provide this by default, used for recursion)
    ///   - delay: The interval between appending characters to the result string
    func type(_ string: String, _ result: String = "", delay: Double = 0.1) {
        var string = string
        let result = "\(result)\(string.removeFirst())"
        receiver(result)
        guard !string.isEmpty else { return }
        queue.asyncAfter(deadline: .now() + delay) {
            self.type(string, result, delay: delay)
        }
    }
    
    
    /// As per `type(string:result:delay:) but with individual delay intervals for each character`
    /// - Parameters:
    ///   - string:
    ///   - result: The string that is being written to (do not provide this by default, used for recursion)
    ///   - delays: an array of delay times, must be equal to one less than the length of `string`
    func type(_ string: String, _ result: String = "", delays: [Double]) {
        assert(delays.count == string.count)
        var string = string
        let result = "\(result)\(string.removeFirst())"
        
        var delays = delays
        let delay = delays.removeFirst()
        
        receiver(result)

        guard !string.isEmpty else { return }
        queue.asyncAfter(deadline: .now() + delay) {
            self.type(string, result, delays: delays)
        }
    }
    
}

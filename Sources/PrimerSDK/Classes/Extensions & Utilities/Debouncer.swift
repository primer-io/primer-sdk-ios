//
//  Debouncer.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval

    init(delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.delay = delay
        self.queue = queue
    }

    func debounce(_ action: @escaping () -> Void) {
        // Cancel the currently pending item
        workItem?.cancel()

        // Create a new work item
        let newWorkItem = DispatchWorkItem(block: action)

        // Save the new work item and schedule it after the delay
        workItem = newWorkItem
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }

    func cancel() {
        workItem?.cancel()
    }
}

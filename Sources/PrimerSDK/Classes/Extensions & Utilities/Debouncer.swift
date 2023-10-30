//
//  Debouncer.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 30/10/2023.
//

import Foundation

class Debouncer {
    private let delay: TimeInterval
    private var timer: Timer?
    private let queue: DispatchQueue
    private var pendingBlock: (() -> Void)?

    init(delay: TimeInterval, labelIdentifier: String) {
        self.delay = delay
        let label = "\(Bundle.primerFrameworkIdentifier).\(labelIdentifier)"
        self.queue = DispatchQueue(label: label, attributes: .concurrent)
    }

    func call(_ block: @escaping () -> Void) {
        queue.async(flags: .barrier) {
            self.pendingBlock = block
            self.resetTimer()
        }
    }

    private func resetTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: delay, repeats: false, block: { [weak self] _ in
            self?.queue.async(flags: .barrier) {
                self?.pendingBlock?()
                self?.pendingBlock = nil
            }
        })
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}

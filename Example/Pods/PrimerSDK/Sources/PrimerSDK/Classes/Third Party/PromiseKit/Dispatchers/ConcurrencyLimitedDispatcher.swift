import Foundation

/// A PromiseKit Dispatcher that allows no more than X simultaneous
/// executions at once.

internal final class ConcurrencyLimitedDispatcher: Dispatcher {
    
    let queue: Dispatcher
    let serializer: DispatchQueue = DispatchQueue(label: "CLD serializer")
    
    let semaphore: DispatchSemaphore
    
    /// A `PromiseKit` `Dispatcher` that allows no more than X simultaneous
    /// executions at once.
    ///
    /// - Parameters:
    ///   - limit: The number of executions that may run at once.
    ///   - queue: The DispatchQueue or Dispatcher on which to perform executions.
    ///       Should be some form of concurrent queue.

    internal init(limit: Int, queue: Dispatcher = DispatchQueue.global(qos: .background)) {
        self.queue = queue
        semaphore = DispatchSemaphore(value: limit)
    }

    internal convenience init(limit: Int, queue: DispatchQueue) {
        self.init(limit: limit, queue: queue as Dispatcher)
    }

    internal func dispatch(_ body: @escaping () -> Void) {
        serializer.async {
            self.semaphore.wait()
            self.queue.dispatch {
                body()
                self.semaphore.signal()
            }
        }
    }
    
}


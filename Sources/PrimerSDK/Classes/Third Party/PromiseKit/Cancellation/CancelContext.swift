import Dispatch
import Foundation

/**
 Keeps track of all promises in a promise chain with pending or currently running tasks, and cancels them all when `cancel` is called.
 */
internal class CancelContext: Hashable {
    internal static func == (lhs: CancelContext, rhs: CancelContext) -> Bool {
        return lhs === rhs
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    // Create a barrier queue that is used as a read/write lock for the CancelContext
    //   For reads:  barrier.sync { }
    //   For writes: barrier.sync(flags: .barrier) { }
    private let barrier = DispatchQueue(label: "org.promisekit.barrier.cancel", attributes: .concurrent)

    private var cancelItems = [CancelItem]()
    private var cancelItemSet = Set<CancelItem>()

    /**
     Cancel all members of the promise chain and their associated asynchronous operations.
     
     - Parameter error: Specifies the cancellation error to use for the cancel operation, defaults to `PMKError.cancelled`
     */
    internal func cancel(with error: Error = PMKError.cancelled) {
        self.cancel(with: error, visited: Set<CancelContext>())
    }

    func cancel(with error: Error = PMKError.cancelled, visited: Set<CancelContext>) {
        var items: [CancelItem]!
        barrier.sync(flags: .barrier) {
            internalCancelledError = error
            items = cancelItems
        }

        for item in items {
            item.cancel(with: error, visited: visited)
        }
    }

    /**
     True if all members of the promise chain have been successfully cancelled, false otherwise.
     */
    internal var isCancelled: Bool {
        var items: [CancelItem]!
        barrier.sync {
            items = cancelItems
        }

        for item in items where !item.isCancelled {
            return false
        }
        return true
    }

    /**
     True if `cancel` has been called on the CancelContext associated with this promise, false otherwise.  `cancelAttempted` will be true if `cancel` is called on any promise in the chain.
     */
    internal var cancelAttempted: Bool {
        return cancelledError != nil
    }

    private var internalCancelledError: Error?

    /**
     The cancellation error initialized when the promise is cancelled, or `nil` if not cancelled.
     */
    internal private(set) var cancelledError: Error? {
        get {
            var err: Error!
            barrier.sync {
                err = internalCancelledError
            }
            return err
        }

        set {
            barrier.sync(flags: .barrier) {
                internalCancelledError = newValue
            }
        }
    }

    func append<Z: CancellableThenable>(cancellable: Cancellable?, reject: ((Error) -> Void)?, thenable: Z) {
        if cancellable == nil && reject == nil {
            return
        }
        let item = CancelItem(cancellable: cancellable, reject: reject)

        var error: Error?
        barrier.sync(flags: .barrier) {
            error = internalCancelledError
            cancelItems.append(item)
            cancelItemSet.insert(item)
            thenable.cancelItemList.append(item)
        }

        if error != nil {
            item.cancel(with: error!)
        }
    }

    func append<Z: CancellableThenable>(context childContext: CancelContext, thenable: Z) {
        guard childContext !== self else {
            return
        }
        let item = CancelItem(context: childContext)

        var error: Error?
        barrier.sync(flags: .barrier) {
            error = internalCancelledError
            cancelItems.append(item)
            cancelItemSet.insert(item)
            thenable.cancelItemList.append(item)
        }

        crossCancel(childContext: childContext, parentCancelledError: error)
    }

    func append(context childContext: CancelContext, thenableCancelItemList: CancelItemList) {
        guard childContext !== self else {
            return
        }
        let item = CancelItem(context: childContext)

        var error: Error?
        barrier.sync(flags: .barrier) {
            error = internalCancelledError
            cancelItems.append(item)
            cancelItemSet.insert(item)
            thenableCancelItemList.append(item)
        }

        crossCancel(childContext: childContext, parentCancelledError: error)
    }

    private func crossCancel(childContext: CancelContext, parentCancelledError: Error?) {
        let parentError = parentCancelledError
        let childError =  childContext.cancelledError

        if parentError != nil {
            if childError == nil {
                childContext.cancel(with: parentError!)
            }
        } else if childError != nil {
            if parentError == nil {
                cancel(with: childError!)
            }
        }
    }

    func recover() {
        cancelledError = nil
    }

    func removeItems(_ list: CancelItemList, clearList: Bool) -> Error? {
        var error: Error?
        barrier.sync(flags: .barrier) {
            error = internalCancelledError
            if error == nil && list.items.count != 0 {
                var currentIndex = 1
                // The `list` parameter should match a block of items in the cancelItemList, remove them from the cancelItemList
                // in one operation for efficiency
                if cancelItemSet.remove(list.items[0]) != nil {
                    let removeIndex = cancelItems.firstIndex(of: list.items[0])!
                    while currentIndex < list.items.count {
                        let item = list.items[currentIndex]
                        if item != cancelItems[removeIndex + currentIndex] {
                            break
                        }
                        cancelItemSet.remove(item)
                        currentIndex += 1
                    }
                    cancelItems.removeSubrange(removeIndex..<(removeIndex+currentIndex))
                }

                // Remove whatever falls outside of the block
                while currentIndex < list.items.count {
                    let item = list.items[currentIndex]
                    if cancelItemSet.remove(item) != nil {
                        cancelItems.remove(at: cancelItems.firstIndex(of: item)!)
                    }
                    currentIndex += 1
                }

                if clearList {
                    list.removeAll()
                }
            }
        }
        return error
    }
}

/// Tracks the cancel items for a CancellablePromise.  These items are removed from the associated CancelContext when the promise resolves.
internal class CancelItemList {
    fileprivate var items: [CancelItem]

    init() {
        self.items = []
    }

    fileprivate func append(_ item: CancelItem) {
        items.append(item)
    }

    fileprivate func removeAll() {
        items.removeAll()
    }
}

private class CancelItem: Hashable {
    static func == (lhs: CancelItem, rhs: CancelItem) -> Bool {
        return lhs === rhs
    }

    internal func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    let cancellable: Cancellable?
    var reject: ((Error) -> Void)?
    weak var context: CancelContext?
    var cancelAttempted = false

    init(cancellable: Cancellable?, reject: ((Error) -> Void)?) {
        self.cancellable = cancellable
        self.reject = reject
    }

    init(context: CancelContext) {
        self.cancellable = nil
        self.context = context
    }

    func cancel(with error: Error, visited: Set<CancelContext>? = nil) {
        cancelAttempted = true

        cancellable?.cancel()
        reject?(error)

        if var v = visited, let c = context {
            if !v.contains(c) {
                v.insert(c)
                c.cancel(with: error, visited: v)
            }
        }
    }

    var isCancelled: Bool {
        return cancellable?.isCancelled ?? cancelAttempted
    }
}

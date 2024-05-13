import struct Foundation.TimeInterval
import Dispatch

/// Extend DispatchWorkItem to be cancellable
extension DispatchWorkItem: Cancellable { }

/**
 after(seconds: 1.5).then {
 //…
 }

 - Returns: A guarantee that resolves after the specified duration.
 - Note: cancelling this guarantee will cancel the underlying timer task
 - SeeAlso: [Cancellation](http://promisekit.org/docs/)
 */
package func after(seconds: TimeInterval) -> Guarantee<Void> {
    let (rgg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + seconds
    let task = DispatchWorkItem { seal(()) }
    rgg.setCancellable(task)
    queue.asyncAfter(deadline: when, execute: task)
    return rgg
}

/**
 after(.seconds(2)).then {
 //…
 }

 - Returns: A guarantee that resolves after the specified duration.
 - Note: cancelling this guarantee will cancel the underlying timer task
 - SeeAlso: [Cancellation](http://promisekit.org/docs/)
 */
package func after(_ interval: DispatchTimeInterval) -> Guarantee<Void> {
    let (rgg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + interval
    let task = DispatchWorkItem { seal(()) }
    rgg.setCancellable(task)
    queue.asyncAfter(deadline: when, execute: task)
    return rgg
}

private var queue: DispatchQueue {
    if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {
        return DispatchQueue.global(qos: .default)
    } else {
        return DispatchQueue.global(priority: .default)
    }
}

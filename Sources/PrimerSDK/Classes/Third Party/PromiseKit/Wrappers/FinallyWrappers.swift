import Dispatch

internal extension _PMKFinallyWrappers {
    /// `finally` is the same as `ensure`, but it is not chainable
    @discardableResult
    func finally(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) -> FinallyReturn {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return finally(on: dispatcher, body)
    }
}

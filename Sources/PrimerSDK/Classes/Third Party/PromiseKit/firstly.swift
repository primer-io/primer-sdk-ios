import Dispatch

/**
 Judicious use of `firstly` *may* make chains more readable.

 Compare:

 URLSession.shared.dataTask(url: url1).then {
 URLSession.shared.dataTask(url: url2)
 }.then {
 URLSession.shared.dataTask(url: url3)
 }

 With:

 firstly {
 URLSession.shared.dataTask(url: url1)
 }.then {
 URLSession.shared.dataTask(url: url2)
 }.then {
 URLSession.shared.dataTask(url: url3)
 }

 - Note: the block you pass executes immediately on the current thread/queue.
 */
internal func firstly<U: Thenable>(execute body: () throws -> U) -> Promise<U.T> {
    do {
        let rp = Promise<U.T>(.pending)
        try body().pipe(to: rp.box.seal)
        return rp
    } catch {
        return Promise(error: error)
    }
}

/// - See: firstly()
internal func firstly<T>(execute body: () -> Guarantee<T>) -> Guarantee<T> {
    return body()
}

//////////////////////////////////////////////////////////// Cancellation

/**
 `firstly` for cancellable promises.

 Compare:

 let context = URLSession.shared.dataTask(url: url1).cancellize().then {
 URLSession.shared.dataTask(url: url2)
 }.then {
 URLSession.shared.dataTask(url: url3)
 }.cancelContext

 // …

 context.cancel()

 With:

 let context = firstly {
 URLSession.shared.dataTask(url: url1)
 }.cancellize().then {
 URLSession.shared.dataTask(url: url2)
 }.then {
 URLSession.shared.dataTask(url: url3)
 }.cancelContext

 // …

 context.cancel()

 - Note: the block you pass excecutes immediately on the current thread/queue.
 - See: firstly(execute: () -> Thenable)
 */
internal func firstly<V: CancellableThenable>(execute body: () throws -> V) -> CancellablePromise<V.U.T> {
    do {
        let rv = try body()
        let rp: CancellablePromise<V.U.T>
        if let promise = rv as? CancellablePromise<V.U.T> {
            rp = promise
        } else {
            rp = CancellablePromise<V.U.T>(rv.thenable)
        }
        rp.appendCancelContext(from: rv)
        return rp
    } catch {
        return CancellablePromise(error: error)
    }
}

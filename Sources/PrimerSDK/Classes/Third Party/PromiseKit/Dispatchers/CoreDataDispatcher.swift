#if !os(Linux)

import Foundation
import CoreData

internal extension NSManagedObjectContext {
    var dispatcher: CoreDataDispatcher {
        return CoreDataDispatcher(self)
    }
}

/// A `Dispatcher` that dispatches onto the threads associated with
/// `NSManagedObjectContext`s, allowing Core Data operations to be
/// handled using promises.

internal struct CoreDataDispatcher: Dispatcher {
    
    let context: NSManagedObjectContext
    
    internal init(_ context: NSManagedObjectContext) {
        self.context = context
    }
    
    internal func dispatch(_ body: @escaping () -> Void) {
        context.perform(body)
    }
    
}

#endif


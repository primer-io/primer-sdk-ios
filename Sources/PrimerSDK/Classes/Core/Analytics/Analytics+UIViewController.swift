import UIKit.UIViewController

typealias Action = Analytics.Event.Property.Action
typealias Place = Analytics.Event.Property.Place
typealias ObjectId = Analytics.Event.Property.ObjectId
typealias ObjectType = Analytics.Event.Property.ObjectType
typealias AnalyticsContext = Analytics.Event.Property.Context

extension UIViewController {
    func postUIEvent(
        _ action: Action,
        context: AnalyticsContext? = nil,
        extra: String? = nil,
        type: ObjectType,
        objectClass: AnyClass? = nil,
        in place: Place,
        id: ObjectId? = nil
    ) {
        Analytics.Service.record(
            event: .ui(
                action: action,
                context: context,
                extra: extra,
                objectType: type,
                objectId: id,
                objectClass: objectClass.map { "\($0.self)" } ?? "\(Self.self)",
                place: place
            )
        )
    }
}

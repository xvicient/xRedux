import SwiftUI

/// Protocol defining the requirements for a state that can show alerts
/// - Note: Must be used on the main actor as it deals with UI
@MainActor
public protocol AppAlertState<Action>: Sendable {
    associatedtype Action: Sendable
    var alert: AppAlert<Action>? { get }
    /// Action sent when the alert is dismissed without going through one of its
    /// buttons (e.g. SwiftUI clears the presentation). Defaults to `nil`, in which
    /// case dismissal is expected to be driven entirely by the buttons' actions.
    var dismissAlertAction: Action? { get }
}

public extension AppAlertState {
    var dismissAlertAction: Action? { nil }
}

/// A structure representing an alert in the application
/// Supports primary and optional secondary actions, with customizable messages
public struct AppAlert<Action: Sendable>: Sendable, Identifiable {
    /// Stable, unique identity for presentation. Two alerts with identical content
    /// still get distinct ids, so re-presenting an equivalent alert works.
    public let id: UUID
    /// The title of the alert
    let title: String
    /// The message body of the alert
    let message: String
    /// The primary action tuple containing the action and its button text
    let primaryAction: (Action, String)
    /// Optional secondary action tuple containing the action and its button text
    let secondaryAction: (Action, String)?

    /// Creates a new alert with the specified parameters
    /// - Parameters:
    ///   - title: The title of the alert (default: empty string)
    ///   - message: The message body of the alert (default: empty string)
    ///   - primaryAction: Tuple of (action, button text) for the primary button
    ///   - secondaryAction: Optional tuple of (action, button text) for the secondary button
    public init(
        title: String = "",
        message: String = "",
        primaryAction: (Action, String),
        secondaryAction: (Action, String)? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    /// Converts the AppAlert to a SwiftUI Alert
    /// - Parameter send: Closure to execute when an action is triggered
    /// - Returns: A configured SwiftUI Alert
    public func alert(
        send: @escaping (Action) -> Void
    ) -> Alert {
        guard let secondaryAction = secondaryAction else {
            return error(send)
        }

        return Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .destructive(Text(primaryAction.1)) {
                send(primaryAction.0)
            },
            secondaryButton: .default(Text(secondaryAction.1)) {
                send(secondaryAction.0)
            }
        )
    }

    /// Creates an alert with only a primary (dismiss) button
    /// - Parameter send: Closure to execute when the dismiss action is triggered
    /// - Returns: A configured SwiftUI Alert
    private func error(
        _ send: @escaping (Action) -> Void
    ) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text(primaryAction.1)) {
                send(primaryAction.0)
            }
        )
    }
}

/// Equatable by content (not identity) when the action is equatable, so alerts can
/// be compared in tests and used in equatable state.
extension AppAlert: Equatable where Action: Equatable {
    public static func == (lhs: AppAlert<Action>, rhs: AppAlert<Action>) -> Bool {
        guard lhs.title == rhs.title,
            lhs.message == rhs.message,
            lhs.primaryAction == rhs.primaryAction
        else {
            return false
        }

        switch (lhs.secondaryAction, rhs.secondaryAction) {
        case (nil, nil):
            return true
        case let (lhsSecondary?, rhsSecondary?):
            return lhsSecondary == rhsSecondary
        default:
            return false
        }
    }
}

/// Extension providing alert binding functionality to Store
@MainActor
public extension Store where R.State: AppAlertState, R.State.Action == R.Action {
    /// A binding to the current alert in the store's state.
    /// The setter reflects SwiftUI-driven dismissal: if the alert is cleared and the
    /// state still holds one, it sends `dismissAlertAction` so state stays in sync.
    /// Guarding on the alert still being present avoids double-firing when a button's
    /// own action already cleared it.
    var alertBinding: Binding<AppAlert<R.State.Action>?> {
        Binding(
            get: { [weak self] in self?.state.alert },
            set: { [weak self] newValue in
                guard let self,
                    newValue == nil,
                    self.state.alert != nil,
                    let dismissAction = self.state.dismissAlertAction
                else { return }
                self.send(dismissAction)
            }
        )
    }
}

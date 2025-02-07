import SwiftUI

/// Protocol defining the requirements for a state that can show alerts
/// - Note: Must be used on the main actor as it deals with UI
@MainActor
public protocol AppAlertState<Action>: Sendable {
    associatedtype Action: Sendable
    var alert: AppAlert<Action>? { get }
}

/// A structure representing an alert in the application
/// Supports primary and optional secondary actions, with customizable messages
public struct AppAlert<Action: Sendable>: Equatable, Sendable, Identifiable {
    /// Unique identifier for the alert, generated from its content
    public var id: String {
        title + message + primaryAction.1 + (secondaryAction?.1 ?? "")
    }
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

    /// Compares two AppAlerts for equality
    /// - Parameters:
    ///   - lhs: Left-hand side AppAlert
    ///   - rhs: Right-hand side AppAlert
    /// - Returns: True if both alerts have the same ID
    public static func == (lhs: AppAlert<Action>, rhs: AppAlert<Action>) -> Bool {
        lhs.id == rhs.id
    }
}

/// Extension providing alert binding functionality to Store
@MainActor
public extension Store where R.State: AppAlertState {
    /// A binding to the current alert in the store's state
    /// The setter is empty as alerts should be managed through actions
    var alertBinding: Binding<AppAlert<R.State.Action>?> {
        Binding(
            get: { [weak self] in self?.state.alert },
            set: { _ in }
        )
    }
}

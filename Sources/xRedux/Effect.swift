import Combine

/// Represents a side effect that can occur as a result of an action in the Redux architecture
public enum Effect<Action> {
    /// Represents no side effect
    case none
    /// Represents a side effect that publishes actions through a Combine publisher
    case publish(AnyPublisher<Action, Never>)
    /// Represents an asynchronous task that can send actions
    /// The task takes a closure that can send actions on the main actor
    case task((@MainActor @escaping (Action) -> Void) async -> Void)
}

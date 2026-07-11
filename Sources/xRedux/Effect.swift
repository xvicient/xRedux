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

extension Effect {
    /// Transforms the action type produced by this effect, allowing a child effect to be lifted
    /// into a parent's action type
    /// - Parameter transform: A closure that converts the effect's action into a new action type
    /// - Returns: An equivalent effect that produces the transformed action type
    public func map<NewAction>(
        _ transform: @escaping @Sendable (Action) -> NewAction
    ) -> Effect<NewAction> {
        switch self {
        case .none:
            return .none
        case .publish(let publisher):
            return .publish(publisher.map(transform).eraseToAnyPublisher())
        case .task(let task):
            return .task { send in
                await task { action in send(transform(action)) }
            }
        }
    }
}

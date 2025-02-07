/// Protocol that defines the core functionality of a Redux reducer
/// A reducer is responsible for evolving the state of an application in response to actions
public protocol Reducer<State, Action> {
    /// The type representing the state that this reducer manages
    associatedtype State
    /// The type representing the actions that this reducer can handle
    /// Must conform to Equatable to enable comparison of actions
    associatedtype Action: Equatable
    
    /// Processes an action and updates the state accordingly
    /// - Parameters:
    ///   - state: The current state to modify
    ///   - action: The action to process
    /// - Returns: An effect that describes any side effects that should occur as a result of this action
    @MainActor
    func reduce(
        _ state: inout State,
        _ action: Action
    ) -> Effect<Action>
}

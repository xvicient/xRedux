public protocol Reducer<State, Action> {
	associatedtype State

	associatedtype Action: Equatable
    
    @MainActor
	func reduce(
		_ state: inout State,
		_ action: Action
	) -> Effect<Action>
}

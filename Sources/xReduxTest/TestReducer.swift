import xRedux

/// A test implementation of the Reducer protocol used for testing Redux state management
/// This class allows tracking state changes and action processing during tests
class TestReducer<State, Action>: Reducer where Action: Equatable {

    /// The actual reduce function that processes actions and updates state
	private let reduce: (inout State, Action) -> Effect<Action>
    /// The most recent action processed by the reducer
	var expectedAction: Action?
    /// The expected state after processing an action
	var expectedState: State
    /// A tuple containing an expected action and a closure to execute when that action is received
	var expectedResult: (Action, () -> Void)?

    /// Creates a new test reducer
    /// - Parameters:
    ///   - reduce: The function that will process actions and update state
    ///   - initialState: The initial state for the reducer
	init(
		reduce: @escaping (inout State, Action) -> Effect<Action>,
		initialState: State
	) {
		self.reduce = reduce
		self.expectedState = initialState
	}

    /// Processes an action and updates the state
    /// Also tracks the action and state changes for test verification
    /// - Parameters:
    ///   - state: The current state to modify
    ///   - action: The action to process
    /// - Returns: An effect that describes any side effects that should occur
	func reduce(
		_ state: inout State,
		_ action: Action
	) -> Effect<Action> {
		expectedState = state
		expectedAction = action
		let effect = reduce(&expectedState, action)
		state = expectedState

		matchExpectedAction(action)

		return effect
	}

    /// Checks if an action matches the expected action and executes the associated closure if it does
    /// - Parameter action: The action to check
    func matchExpectedAction(_ action: Action) {
		guard expectedResult?.0 == action else {
			return
		}
		expectedResult?.1()
	}
}

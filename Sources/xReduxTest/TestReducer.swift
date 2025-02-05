import xRedux

class TestReducer<State, Action>: Reducer where Action: Equatable {

	private let reduce: (inout State, Action) -> Effect<Action>
	var expectedAction: Action?
	var expectedState: State
	var expectedResult: (Action, () -> Void)?

	init(
		reduce: @escaping (inout State, Action) -> Effect<Action>,
		initialState: State
	) {
		self.reduce = reduce
		self.expectedState = initialState
	}

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

	func matchExpectedAction(_ action: Action) {
		guard expectedResult?.0 == action else {
			return
		}
		expectedResult?.1()
	}
}

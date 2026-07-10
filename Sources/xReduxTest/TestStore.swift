import xRedux

@MainActor
public final class TestStore<State, Action> where Action: Equatable {
	private let store: Store<TestReducer<State, Action>>
	private let reducer: TestReducer<State, Action>

    public init<R: Reducer>(
		initialState: State,
		reducer: R
	)
	where
		R.State == State,
		R.Action == Action
	{
		self.reducer = TestReducer(
			reduce: reducer.reduce,
			initialState: initialState
		)
		self.store = Store(initialState: initialState, reducer: self.reducer)
	}

    public func send(
		_ action: Action,
		assert expectation: ((_ state: State) -> Bool)
	) async {
		store.send(action)
        precondition(reducer.expectedAction == action)
        precondition(expectation(reducer.expectedState))
	}

    public func receive(
		timeout milliseconds: Int = 5000,
		_ action: Action,
		assert expectation: @escaping ((_ state: State) -> Bool)
	) async {
		var expectedResultReceived = false
		var elapsedMilliseconds = 0
		let paceMilliseconds = 100

		reducer.expectedResult = (
			action,
			{ [weak self] in
				guard let self else { return }
                precondition(reducer.expectedAction == action)
                precondition(expectation(reducer.expectedState))
				expectedResultReceived = true
			}
		)

		while !expectedResultReceived && elapsedMilliseconds < milliseconds {
			elapsedMilliseconds += paceMilliseconds
			try? await Task.sleep(nanoseconds: UInt64(paceMilliseconds) * 1_000_000)
		}

        precondition(expectedResultReceived, "Timeout waiting for expected action")
	}
}

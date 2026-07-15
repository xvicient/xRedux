import Testing
import xRedux

/// A test harness around ``Store`` that records failures through Swift Testing
/// instead of crashing the process. Assertions report against the caller's
/// source location so failures point at the test, not the library.
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

    /// Sends an action synchronously and asserts the resulting state.
    /// - Parameters:
    ///   - action: The action to send.
    ///   - expectation: Returns `true` when the resulting state is as expected.
    ///   - sourceLocation: Caller location; defaults to the call site.
    public func send(
		_ action: Action,
		assert expectation: (_ state: State) -> Bool,
		sourceLocation: SourceLocation = #_sourceLocation
	) async {
		store.send(action)

		if reducer.expectedAction != action {
			Issue.record(
				"Expected the reducer to process \(action) but it processed \(String(describing: reducer.expectedAction))",
				sourceLocation: sourceLocation
			)
		}

		if !expectation(reducer.expectedState) {
			Issue.record(
				"State assertion failed after sending \(action)",
				sourceLocation: sourceLocation
			)
		}
	}

    /// Waits for an action produced by an effect and asserts the resulting state.
    /// - Parameters:
    ///   - milliseconds: Maximum time to wait before recording a timeout.
    ///   - action: The action expected to arrive from an effect.
    ///   - expectation: Returns `true` when the resulting state is as expected.
    ///   - sourceLocation: Caller location; defaults to the call site.
    public func receive(
		timeout milliseconds: Int = 5000,
		_ action: Action,
		assert expectation: @escaping (_ state: State) -> Bool,
		sourceLocation: SourceLocation = #_sourceLocation
	) async {
		var assertionPassed = false
		var expectedResultReceived = false
		var elapsedMilliseconds = 0
		let paceMilliseconds = 100

		reducer.expectedResult = (
			action,
			{ [weak self] in
				guard let self else { return }
				assertionPassed =
					reducer.expectedAction == action && expectation(reducer.expectedState)
				expectedResultReceived = true
			}
		)

		while !expectedResultReceived && elapsedMilliseconds < milliseconds {
			elapsedMilliseconds += paceMilliseconds
			try? await Task.sleep(nanoseconds: UInt64(paceMilliseconds) * 1_000_000)
		}

		guard expectedResultReceived else {
			Issue.record(
				"Timed out after \(milliseconds)ms waiting to receive \(action)",
				sourceLocation: sourceLocation
			)
			return
		}

		if !assertionPassed {
			Issue.record(
				"State assertion failed after receiving \(action)",
				sourceLocation: sourceLocation
			)
		}
	}
}

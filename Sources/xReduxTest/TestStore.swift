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

		// A directly-sent action is asserted here; keep it out of `receive`'s view.
		reducer.consumeSent(action)
	}

    /// Waits for an action produced by an effect and asserts the resulting state.
    /// The happy path is fully deterministic (no polling); the timeout only races a
    /// sleep on the failure path.
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
		guard await waitForAction(action, milliseconds: milliseconds) else {
			Issue.record(
				"Timed out after \(milliseconds)ms waiting to receive \(action)",
				sourceLocation: sourceLocation
			)
			return
		}

		if reducer.expectedAction != action {
			Issue.record(
				"Expected to receive \(action) but the reducer processed \(String(describing: reducer.expectedAction))",
				sourceLocation: sourceLocation
			)
		}

		if !expectation(reducer.expectedState) {
			Issue.record(
				"State assertion failed after receiving \(action)",
				sourceLocation: sourceLocation
			)
		}
	}

    /// Awaits the reducer's hook for `action`. A timeout task releases the wait if the
    /// action never arrives. Returns `true` when received, `false` on timeout.
    private func waitForAction(_ action: Action, milliseconds: Int) async -> Bool {
		let timeout = Task { [reducer] in
			try? await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
			// If we get here without being cancelled, the action never arrived.
			reducer.cancelWait()
		}
		defer { timeout.cancel() }

		return await reducer.waitForAction(action)
	}
}

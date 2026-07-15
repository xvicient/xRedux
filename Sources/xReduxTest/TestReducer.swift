import xRedux

/// A test implementation of the Reducer protocol used for testing Redux state management.
/// It wraps the real reduce function, tracks the latest action/state, and lets
/// `TestStore.receive` await effect-produced actions deterministically (no polling).
@MainActor
final class TestReducer<State, Action>: Reducer where Action: Equatable {

    /// The actual reduce function that processes actions and updates state
	private let reduceFunction: (inout State, Action) -> Effect<Action>
    /// The most recent action processed by the reducer
	var expectedAction: Action?
    /// The expected state after processing an action
	var expectedState: State

    /// Actions already processed but not yet consumed by a `receive`.
	private var buffer: [Action] = []
    /// A pending `receive` waiting for a specific action.
	private var waiter: (action: Action, resume: (Bool) -> Void)?

    /// Creates a new test reducer
    /// - Parameters:
    ///   - reduce: The function that will process actions and update state
    ///   - initialState: The initial state for the reducer
	init(
		reduce: @escaping (inout State, Action) -> Effect<Action>,
		initialState: State
	) {
		self.reduceFunction = reduce
		self.expectedState = initialState
	}

    /// Processes an action, updates the state, and routes the action to a waiting
    /// `receive` (or buffers it for a later one).
	func reduce(
		_ state: inout State,
		_ action: Action
	) -> Effect<Action> {
		expectedState = state
		expectedAction = action
		let effect = reduceFunction(&expectedState, action)
		state = expectedState

		deliver(action)

		return effect
	}

    /// Routes a processed action to a waiting `receive`, or buffers it.
	private func deliver(_ action: Action) {
		if let waiter, waiter.action == action {
			self.waiter = nil
			waiter.resume(true)
		}
		else {
			buffer.append(action)
		}
	}

    /// Discards a directly-sent action from the buffer, so `receive` only ever
    /// observes actions produced by effects.
	func consumeSent(_ action: Action) {
		if let index = buffer.lastIndex(of: action) {
			buffer.remove(at: index)
		}
	}

    /// Suspends until `action` is processed. Returns `true` when matched, or `false`
    /// if the wait was released without a match (e.g. by a timeout).
	func waitForAction(_ action: Action) async -> Bool {
		if let index = buffer.firstIndex(of: action) {
			buffer.removeFirst(index + 1)
			return true
		}
		return await withCheckedContinuation { continuation in
			waiter = (action, { matched in continuation.resume(returning: matched) })
		}
	}

    /// Releases a pending wait without a match, so a timed-out `receive` can finish.
	func cancelWait() {
		guard let waiter else { return }
		self.waiter = nil
		waiter.resume(false)
	}
}

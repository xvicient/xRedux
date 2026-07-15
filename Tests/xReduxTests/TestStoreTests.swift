import Testing
import xRedux
import xReduxTest

/// Regression tests for `TestStore`: assertions must report Swift Testing
/// failures instead of crashing the process (issue #1 in the improvement plan).
@MainActor
struct TestStoreTests {

	/// A minimal counter reducer with both a synchronous action and an
	/// effect-produced action, exercising `send` and `receive`.
	private struct CounterReducer: Reducer {
		struct State: Equatable {
			var count = 0
		}

		enum Action: Equatable {
			case increment
			case incrementLater
			case didIncrementLater
		}

		func reduce(_ state: inout State, _ action: Action) -> Effect<Action> {
			switch action {
			case .increment:
				state.count += 1
				return .none
			case .incrementLater:
				return .task { send in
					send(.didIncrementLater)
				}
			case .didIncrementLater:
				state.count += 1
				return .none
			}
		}
	}

	private func makeStore() -> TestStore<CounterReducer.State, CounterReducer.Action> {
		TestStore(initialState: .init(), reducer: CounterReducer())
	}

	@Test("A correct send assertion passes without recording an issue")
	func sendSucceeds() async {
		let store = makeStore()
		await store.send(.increment) { $0.count == 1 }
	}

	@Test("A wrong send state assertion records an issue instead of crashing")
	func sendWrongStateRecordsIssue() async {
		let store = makeStore()
		await withKnownIssue {
			await store.send(.increment) { $0.count == 99 }
		}
	}

	@Test("A correct receive assertion passes for an effect-produced action")
	func receiveSucceeds() async {
		let store = makeStore()
		await store.send(.incrementLater) { $0.count == 0 }
		await store.receive(.didIncrementLater) { $0.count == 1 }
	}

	@Test("A wrong receive state assertion records an issue instead of crashing")
	func receiveWrongStateRecordsIssue() async {
		let store = makeStore()
		await store.send(.incrementLater) { $0.count == 0 }
		await withKnownIssue {
			await store.receive(.didIncrementLater) { $0.count == 99 }
		}
	}

	@Test("Receiving an action that never arrives records a timeout issue")
	func receiveTimeoutRecordsIssue() async {
		let store = makeStore()
		await withKnownIssue {
			await store.receive(timeout: 200, .didIncrementLater) { _ in true }
		}
	}
}

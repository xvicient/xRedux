import Testing

@testable import xRedux

/// Regression tests for `Store`'s internal effect lifecycle (issue #3 in the plan):
/// in-flight tasks must not outlive the store.
@MainActor
struct StoreTests {

	/// Shared signal between the test and the effect's task.
	private final class Signal: @unchecked Sendable {
		var started = false
		var cancelled = false
	}

	private struct LongTaskReducer: Reducer {
		let signal: Signal

		struct State: Equatable {}
		enum Action: Equatable { case start }

		func reduce(_ state: inout State, _ action: Action) -> Effect<Action> {
			.task { [signal] _ in
				await withTaskCancellationHandler {
					signal.started = true
					// Suspend until the surrounding task is cancelled.
					try? await Task.sleep(nanoseconds: .max)
				} onCancel: {
					signal.cancelled = true
				}
			}
		}
	}

	@Test("A task still in flight is cancelled when the store is deallocated")
	func inFlightTaskCancelledOnDeinit() async {
		let signal = Signal()
		var store: Store<LongTaskReducer>? = Store(
			initialState: .init(),
			reducer: LongTaskReducer(signal: signal)
		)

		store?.send(.start)

		// Let the task begin and install its cancellation handler.
		while !signal.started {
			await Task.yield()
		}

		#expect(signal.cancelled == false)

		// Releasing the store must cancel the task via deinit.
		store = nil

		#expect(signal.cancelled == true)
	}
}

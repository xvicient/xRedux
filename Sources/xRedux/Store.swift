import Combine
import SwiftUI

/// A class that manages the state and handles actions in a Redux-style architecture
/// Conforms to ObservableObject to enable SwiftUI view updates
@Observable public final class Store<R: Reducer> {
    /// A single in-flight side effect, cancellable regardless of its underlying kind.
    /// Cancellation is internal machinery: reducers only ever deal with `Effect`,
    /// while the store owns each effect's lifetime and tears it down when appropriate.
    private enum RunningEffect {
        case subscription(AnyCancellable)
        case task(Task<Void, Never>)

        func cancel() {
            switch self {
            case .subscription(let cancellable):
                cancellable.cancel()
            case .task(let task):
                task.cancel()
            }
        }
    }

    /// The current state of the application, published to enable view updates
	private(set) public var state: R.State
    /// The reducer that processes actions and updates state
	private let reducer: R
    /// Every in-flight effect, keyed by an internal token so each can be removed on
    /// completion and cancelled if the store goes away.
	private var running: [UUID: RunningEffect] = [:]

    /// Creates a new Store with an initial state and reducer
    /// - Parameters:
    ///   - initialState: The initial state of the application
    ///   - reducer: The reducer that will process actions and update state
    public init(
		initialState: R.State,
		reducer: R
	) {
		self.state = initialState
		self.reducer = reducer
	}

    deinit {
        // Nothing should outlive the store: cancel any effect still in flight.
        running.values.forEach { $0.cancel() }
    }

    /// Sends an action to be processed by the reducer, then runs the resulting effect.
    /// - Parameter action: The action to process
    /// This method handles different types of effects that may result from processing the action:
    /// - none: No side effects
    /// - publish: Side effects that produce actions through a publisher
    /// - task: Asynchronous side effects that can send actions
    @MainActor
    public func send(_ action: R.Action) {
		switch reducer.reduce(&state, action) {
		case .none:
			break

		case .publish(let publisher):
			let token = UUID()
			running[token] = .subscription(
				publisher
					.receive(on: DispatchQueue.main)
					.sink(
						receiveCompletion: { [weak self] _ in
							self?.running[token] = nil
						},
						receiveValue: { [weak self] action in
							self?.send(action)
						}
					)
			)

		case .task(let work):
			let token = UUID()
			running[token] = .task(
				Task { [weak self] in
					await work { action in self?.send(action) }
					self?.running[token] = nil
				}
			)
		}
	}
}

import Combine
import SwiftUI

/// A class that manages the state and handles actions in a Redux-style architecture
/// Conforms to ObservableObject to enable SwiftUI view updates
public final class Store<R: Reducer>: ObservableObject {
    /// The current state of the application, published to enable view updates
	@Published private(set) public var state: R.State
    /// The reducer that processes actions and updates state
	private let reducer: R
    /// Set of cancellables to manage publisher lifecycles
	private var cancellables: Set<AnyCancellable> = []

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

    /// Sends an action to be processed by the reducer
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
			publisher
				.receive(on: DispatchQueue.main)
				.sink(receiveValue: send)
				.store(in: &cancellables)
		case .task(let task):
			Task {
				await task { action in
					self.send(action)
				}
			}
		}
	}
}

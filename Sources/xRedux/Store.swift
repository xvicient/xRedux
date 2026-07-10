import Combine
import SwiftUI

/// A class that manages the state and handles actions in a Redux-style architecture
/// Conforms to ObservableObject to enable SwiftUI view updates
@Observable public final class Store<R: Reducer> {
    /// The current state of the application, published to enable view updates
	private(set) public var state: R.State
    /// The reducer that processes actions and updates state
	private let reducer: R
    /// Cancellables keyed by subscription id, so each is removed as soon as its publisher completes
	private var cancellables: [UUID: AnyCancellable] = [:]

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
			let id = UUID()
			cancellables[id] = publisher
				.receive(on: DispatchQueue.main)
				.sink(
					receiveCompletion: { [weak self] _ in
						self?.cancellables[id] = nil
					},
					receiveValue: { [weak self] action in
						self?.send(action)
					}
				)
		case .task(let task):
			Task { [weak self] in
				await task { action in
					self?.send(action)
				}
			}
		}
	}
}

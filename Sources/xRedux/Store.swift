import Combine
import SwiftUI

public final class Store<R: Reducer>: ObservableObject {
	@Published private(set) public var state: R.State
	private let reducer: R
	private var cancellables: Set<AnyCancellable> = []

    public init(
		initialState: R.State,
		reducer: R
	) {
		self.state = initialState
		self.reducer = reducer
	}

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

import Foundation
import xRedux

/// Grocery lists screen. Wraps ToggleableListReducer and adds the  action
/// sharing a list's name.
struct ListsReducer<UseCase: ListsUseCaseApi>: Reducer {
    typealias State = ToggleableListReducer<UseCase>.State

    enum Action: Equatable, Sendable {
        case shared(ToggleableListReducer<UseCase>.Action)
        case didTapShare(UUID)
    }

    private let sharedReducer: ToggleableListReducer<UseCase>

    init(useCase: UseCase) {
        self.sharedReducer = ToggleableListReducer(useCase: useCase)
    }

    func reduce(
        _ state: inout State,
        _ action: Action
    ) -> Effect<Action> {
        switch action {
        case .shared(let sharedAction):
            return sharedReducer.reduce(&state, sharedAction).map { .shared($0) }

        case .didTapShare:
            // ListsView's ShareLink handles presentation; this is just the hook for it.
            return .none
        }
    }
}

extension Store where R == ListsReducer<ListsUseCase> {
    var pendingLists: [GroceryList] {
        get {
            state.items.filter { !$0.completed }
        }
        set { }
    }

    var completedLists: [GroceryList] {
        get {
            state.items.filter { $0.completed }
        }
        set { }
    }
}

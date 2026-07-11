import Foundation
import xRedux

/// Manages the grocery lists. Reuses the shared fetch/toggle logic from ToggleableListReducer
/// and adds the one action Items doesn't need: selecting a list to navigate into its items.
/// Generic over UseCase so tests can inject a mock while production uses ListsUseCase.
struct ListsReducer<UseCase: ListsUseCaseApi>: Reducer {
    typealias State = ToggleableListReducer<UseCase>.State

    enum Action: Equatable, Sendable {
        case shared(ToggleableListReducer<UseCase>.Action)
        case didSelectList(UUID)
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

        case .didSelectList:
            // Navigation itself is handled by ListsView (see navigationDestination(item:)).
            // This action is the extension point Items doesn't have.
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

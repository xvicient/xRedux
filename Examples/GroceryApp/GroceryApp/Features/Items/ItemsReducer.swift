import Foundation
import xRedux

/// Items of a single grocery list. Wraps ToggleableListReducer,
/// adds deletion, and carries the list's name for the navigation title.
struct ItemsReducer<UseCase: ItemsUseCaseApi>: Reducer {
    struct State {
        var shared = ToggleableListReducer<UseCase>.State()
        let listName: String

        init(listName: String) {
            self.listName = listName
        }
    }

    enum Action: Equatable, Sendable {
        case shared(ToggleableListReducer<UseCase>.Action)
        case didDeleteItem(UUID)
    }

    private let useCase: UseCase
    private let sharedReducer: ToggleableListReducer<UseCase>

    init(useCase: UseCase) {
        self.useCase = useCase
        self.sharedReducer = ToggleableListReducer(useCase: useCase)
    }

    func reduce(
        _ state: inout State,
        _ action: Action
    ) -> Effect<Action> {
        switch action {
        case .shared(let sharedAction):
            return sharedReducer.reduce(&state.shared, sharedAction).map(Action.shared)

        case .didDeleteItem(let id):
            guard let index = state.shared.items.firstIndex(where: { $0.id == id }) else {
                return .none
            }
            let item = state.shared.items.remove(at: index)
            // Fire-and-forget: the item is already removed from state above.
            return .task { _ in
                await useCase.deleteElement(item)
            }
        }
    }
}

extension Store where R == ItemsReducer<ItemsUseCase> {
    var pendingItems: [Item] {
        get {
            state.shared.items.filter { !$0.completed }
        }
        set { }
    }

    var completedItems: [Item] {
        get {
            state.shared.items.filter { $0.completed }
        }
        set { }
    }
}

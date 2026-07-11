import xRedux

/// Manages the items of a single grocery list. No behavior of its own beyond the shared
/// fetch/toggle logic in ToggleableListReducer.
typealias ItemsReducer = ToggleableListReducer<ItemsUseCase>

extension Store<ItemsReducer> {
    var pendingItems: [Item] {
        get {
            state.items.filter { !$0.completed }
        }
        set { }
    }

    var completedItems: [Item] {
        get {
            state.items.filter { $0.completed }
        }
        set { }
    }
}

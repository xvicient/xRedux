import Observation
import xRedux

/// Owns navigation and the root Store, built once here so push/pop never reconstructs it.
/// Never reads a feature's Store, so feature state changes can't invalidate CoordinatorView.
@MainActor
@Observable
final class Coordinator {
    var path: [GroceryList] = []
    let listsStore: Store<ListsReducer<ListsUseCase>>

    init() {
        listsStore = Store(
            initialState: .init(),
            reducer: ListsReducer(useCase: ListsUseCase())
        )
    }

    func push(_ list: GroceryList) {
        path.append(list)
    }
}

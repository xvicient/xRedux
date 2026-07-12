import SwiftUI
import xRedux

struct ItemsBuilder {
    static func makeItems(for list: GroceryList) -> some View {
        ItemsView(
            store: Store(
                initialState: .init(listName: list.name),
                reducer: ItemsReducer(
                    useCase: ItemsUseCase()
                )
            )
        )
    }
}

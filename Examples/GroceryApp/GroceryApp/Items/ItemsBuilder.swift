import SwiftUI
import xRedux

struct ItemsBuilder {
    static func makeItems(for list: GroceryList) -> some View {
        ItemsView(
            listName: list.name,
            store: Store(
                initialState: .init(),
                reducer: ItemsReducer(
                    useCase: ItemsUseCase()
                )
            )
        )
    }
}

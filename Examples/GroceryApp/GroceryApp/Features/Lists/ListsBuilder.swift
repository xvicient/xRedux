import SwiftUI
import xRedux

struct ListsBuilder {
    static func makeLists(
        store: Store<ListsReducer<ListsUseCase>>,
        coordinator: Coordinator
    ) -> some View {
        ListsView(store: store, coordinator: coordinator)
    }
}

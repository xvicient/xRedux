import SwiftUI
import xRedux

struct ListsBuilder {
    static func makeLists() -> some View {
        ListsView(
            store: Store(
                initialState: .init(),
                reducer: ListsReducer(
                    useCase: ListsUseCase()
                )
            )
        )
    }
}

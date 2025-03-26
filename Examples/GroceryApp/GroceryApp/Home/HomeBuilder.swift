import SwiftUI
import xRedux

struct HomeBuilder {
    public static func makeHome(
    ) -> some View {
        HomeView(
            store: Store(
                initialState: .init(),
                reducer: HomeReducer(
                    useCase: HomeUseCase()
                )
            )
        )
    }
}

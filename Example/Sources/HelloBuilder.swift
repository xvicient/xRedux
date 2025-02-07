import SwiftUI
import xRedux

public struct Hello {
    @MainActor
    public struct Builder {
        
        public static func makeHello(
        ) -> some View {
            HelloScreen(
                store: Store(
                    initialState: .init(),
                    reducer: Reducer()
                )
            )
        }
    }
}

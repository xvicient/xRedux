import xRedux
import SwiftUI

struct HelloScreen: View {
    @ObservedObject private var store: Store<Hello.Reducer>
    
    init(
        store: Store<Hello.Reducer>
    ) {
        self.store = store
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 24) {
                Button("Say hello!") {
                    store.send(.didTapSayHello)
                }
                .buttonStyle(.bordered)
                Text(store.state.viewModel.content)
            }
            Spacer()
        }
        .onAppear {
            store.send(.onViewAppear)
        }
    }
}

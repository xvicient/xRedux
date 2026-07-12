import SwiftUI

/// Only reads `coordinator.path`, never a feature's Store, so feature state changes never
/// rebuild an already-pushed destination.
struct CoordinatorView: View {
    @Bindable private var coordinator: Coordinator

    init(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ListsBuilder.makeLists(store: coordinator.listsStore, coordinator: coordinator)
                .navigationDestination(for: GroceryList.self) { list in
                    ItemsBuilder.makeItems(for: list)
                }
        }
    }
}

#Preview {
    CoordinatorView(coordinator: Coordinator())
}

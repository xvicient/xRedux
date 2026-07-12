import SwiftUI
import xRedux

struct ListsView: View {
    @Bindable private var store: Store<ListsReducer<ListsUseCase>>
    private let coordinator: Coordinator

    init(store: Store<ListsReducer<ListsUseCase>>, coordinator: Coordinator) {
        self.store = store
        self.coordinator = coordinator
    }

    var body: some View {
        List {
            Section(header: Text("To do")) {
                ForEach(store.pendingLists) { list in
                    row(for: list)
                }
            }
            Section(header: Text("Done")) {
                ForEach(store.completedLists) { list in
                    row(for: list)
                }
            }
        }
        .navigationTitle("Grocery Lists")
        .onAppear {
            store.send(.shared(.onAppear))
        }
    }

    private func row(for list: GroceryList) -> some View {
        HStack {
            Button(action: {
                store.send(.shared(.didTapItem(list.id)))
            }) {
                Image(systemName: list.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(list.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("toggle-\(list.name)")
            .accessibilityLabel(list.completed ? "Completed" : "Not completed")

            Text(list.name)
                .strikethrough(list.completed, color: .gray)
                .foregroundColor(list.completed ? .gray : .primary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            coordinator.push(list)
        }
        .swipeActions(edge: .leading) {
            ShareLink(item: list.name) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
            .simultaneousGesture(TapGesture().onEnded {
                store.send(.didTapShare(list.id))
            })
        }
    }
}

#Preview {
    CoordinatorView(coordinator: Coordinator())
}

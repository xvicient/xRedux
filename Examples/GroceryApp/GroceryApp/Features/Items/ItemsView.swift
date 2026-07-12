import SwiftUI
import xRedux

struct ItemsView: View {
    @Bindable private var store: Store<ItemsReducer<ItemsUseCase>>

    init(store: Store<ItemsReducer<ItemsUseCase>>) {
        self.store = store
    }

    var body: some View {
        List {
            Section(header: Text("To buy")) {
                ForEach(store.pendingItems) { item in
                    row(for: item)
                }
            }
            Section(header: Text("Into the basket")) {
                ForEach(store.completedItems) { item in
                    row(for: item)
                }
            }
        }
        .navigationTitle(store.state.listName)
        .onAppear {
            store.send(.shared(.onAppear))
        }
    }

    private func row(for item: Item) -> some View {
        HStack {
            Button(action: {
                store.send(.shared(.didTapItem(item.id)))
            }) {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            Text(item.name)
                .strikethrough(item.completed, color: .gray)
                .foregroundColor(item.completed ? .gray : .primary)
        }
        .padding(.vertical, 4)
        .swipeActions {
            Button(role: .destructive) {
                store.send(.didDeleteItem(item.id))
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItemsBuilder.makeItems(for: GroceryList(name: "Preview List", completed: false))
    }
}

import SwiftUI
import xRedux

struct ItemsView: View {
    let listName: String
    @State private var store: Store<ItemsReducer>

    init(listName: String, store: Store<ItemsReducer>) {
        self.listName = listName
        self._store = State(initialValue: store)
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
        .navigationTitle(listName)
        .onAppear {
            store.send(.onAppear)
        }
    }

    private func row(for item: Item) -> some View {
        HStack {
            Button(action: {
                store.send(.didTapItem(item.id))
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
    }
}

#Preview {
    NavigationStack {
        ItemsBuilder.makeItems(for: GroceryList(name: "Preview List", completed: false))
    }
}

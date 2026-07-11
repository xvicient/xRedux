import SwiftUI
import xRedux

struct ListsView: View {
    @State private var selectedList: GroceryList?
    @State private var store: Store<ListsReducer<ListsUseCase>>

    init(store: Store<ListsReducer<ListsUseCase>>) {
        self._store = State(initialValue: store)
    }

    var body: some View {
        NavigationStack {
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
            .navigationDestination(item: $selectedList) { list in
                ItemsBuilder.makeItems(for: list)
            }
        }
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

            Text(list.name)
                .strikethrough(list.completed, color: .gray)
                .foregroundColor(list.completed ? .gray : .primary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            store.send(.didSelectList(list.id))
            selectedList = list
        }
    }
}

#Preview {
    ListsBuilder.makeLists()
}

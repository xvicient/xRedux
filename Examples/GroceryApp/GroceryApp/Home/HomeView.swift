import SwiftUI
import xRedux

struct HomeView: View {
    private var store: Store<HomeReducer>
    
    init(store: Store<HomeReducer>) {
        self.store = store
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("To buy")) {
                    ForEach(store.pendingItems) { item in
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
                Section(header: Text("Into the basket")) {
                    ForEach(store.completedItems) { item in
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
            }
            .navigationTitle("Grocery List")
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

#Preview {
    HomeBuilder.makeHome()
}

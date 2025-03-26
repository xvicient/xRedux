import Foundation

struct Item: Equatable, Identifiable {
    let id = UUID()
    let name: String
    var completed: Bool
}

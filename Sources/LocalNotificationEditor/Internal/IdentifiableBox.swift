import Foundation

struct IdentifiableBox<Value, ID: Hashable>: Identifiable {
    let id: ID
    let value: Value

    init(value: Value, id: KeyPath<Value, ID>) {
        self.value = value
        self.id = value[keyPath: id]
    }
}

import Foundation

extension [String: Any] {
    func json() -> String {
        guard JSONSerialization.isValidJSONObject(self),
              let json = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .sortedKeys]),
              let jsonString = String(data: json, encoding: .utf8)
        else {
            return "{}"
        }
        return jsonString
    }
}

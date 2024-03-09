import Foundation
import UserNotifications

public protocol UNUserNotificationCenterProtocol {
    func add(_ request: UNNotificationRequest) async throws
    func removeAllPendingNotificationRequests()
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers: [String])
}

extension UNUserNotificationCenter: UNUserNotificationCenterProtocol {}

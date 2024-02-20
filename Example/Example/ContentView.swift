import SwiftUI
import LocalNotificationEditor
import UserNotifications

struct ContentView: View {
    var body: some View {
        NavigationStack {
            LocalNotificationList(userNotificationCenter: .current())
        }
        .task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        }
    }
}

#Preview {
    ContentView()
}

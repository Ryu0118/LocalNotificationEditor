# LocalNotificationEditor
A SwiftUI view for easily displaying, adding, removing, and editing local notifications for debugging.

<img src="https://github.com/Ryu0118/LocalNotificationEditor/assets/87907656/d503f06c-a2ef-41f2-b9c2-c161e81e1938" width=250>
<img src="https://github.com/Ryu0118/LocalNotificationEditor/assets/87907656/d58591fc-9b9f-416a-9382-c5046818ec81" width=250>
<img src="https://github.com/Ryu0118/LocalNotificationEditor/assets/87907656/890218a9-d2f2-4ae7-967c-654a2cf3c812" width=250>

# Usage
Here's a example code:
```Swift
import SwiftUI
import LocalNotificationEditor

public struct MyView: View {
  public var body: some View {
    NavigationStack {
      LocalNotificationList(userNotificationCenter: .current())
    }
  }
}
```

import SwiftUI
import UserNotifications

public struct LocalNotificationList: View {
    @State var notificationRequests: [UNNotificationRequest] = []
    @State var selectedRequest: IdentifiableBox<UNNotificationRequest, String>?
    @State var isAddNotificationEditorPresented = false
    @State var isDeleteAllAlertPresented = false

    let userNotificationCenter: UNUserNotificationCenter

    public init(userNotificationCenter: UNUserNotificationCenter) {
        self.userNotificationCenter = userNotificationCenter
    }

    public var body: some View {
        List {
            ForEach(notificationRequests, id: \.identifier) { request in
                HStack {
                    VStack(alignment: .leading) {
                        if !request.content.title.isEmpty {
                            Text(request.content.title)
                                .font(.title3.bold())
                        }
                        if !request.content.subtitle.isEmpty {
                            Text(request.content.subtitle)
                                .font(.headline.bold())
                        }
                        if !request.content.body.isEmpty {
                            Text(request.content.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("id: " + request.identifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedRequest = IdentifiableBox(
                        value: request,
                        id: \.identifier
                    )
                }
            }
            .onDelete { indexSet in
                userNotificationCenter.removePendingNotificationRequests(
                    withIdentifiers: indexSet.map {
                        notificationRequests[$0].identifier
                    }
                )
                notificationRequests.remove(atOffsets: indexSet)
            }
        }
        .overlay {
            if notificationRequests.isEmpty, #available(iOS 17.0, *) {
                ContentUnavailableView(
                    "No Pending Notifications",
                    systemImage: "bell.slash.fill",
                    description: Text("You currently have no notifications scheduled. Use the '+' button to add new notifications.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isDeleteAllAlertPresented = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddNotificationEditorPresented = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Do you really want to delete all notifications?", isPresented: $isDeleteAllAlertPresented) {
            Button(role: .cancel) {
            } label: {
                Text("Cancel")
            }
            Button(role: .destructive) {
                userNotificationCenter.removeAllPendingNotificationRequests()
                Task {
                    await update()
                }
            } label: {
                Text("Delete")
            }
        }
        .sheet(item: $selectedRequest) { box in
            LocalNotificationEditor(
                userNotificationCenter: userNotificationCenter,
                mode: .edit(box.value),
                onSave: {
                    Task {
                        await update()
                    }
                }
            )
        }
        .sheet(isPresented: $isAddNotificationEditorPresented) {
            LocalNotificationEditor(
                userNotificationCenter: userNotificationCenter,
                mode: .add,
                onSave: {
                    Task {
                        await update()
                    }
                }
            )
        }
        .refreshable {
            await update()
        }
        .task {
            await update()
        }
    }

    private func update() async {
        notificationRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}

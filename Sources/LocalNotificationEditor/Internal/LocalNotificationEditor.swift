import SwiftUI
import UserNotifications
import CoreLocation

struct LocalNotificationEditor: View {
    @Environment(\.dismiss) private var dismiss

    @State var identifier: String
    @State var title: String
    @State var subtitle: String
    @State var bodyString: String
    @State var attachments: [(identifier: String, url: URL)]
    @State var badge: Int?
    @State var categoryIdentifier: String
    @State var filterCriteria: String?
    @State var interruptionLevel: UInt
    @State var launchImageName: String
    @State var relevanceScore: Double
    @State var targetContentIdentifier: String?
    @State var threadIdentifier: String
    @State var userInfoString: String = ""
    @State var triggerType: TriggerType?

    var userInfo: [AnyHashable: Any] {
        guard let data = userInfoString.data(using: .utf8),
              let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }
        return value.compactMapKeys { AnyHashable($0) }
    }

    var isSaveButtonEnabled: Bool {
        !identifier.isEmpty && (!title.isEmpty || !subtitle.isEmpty || !bodyString.isEmpty)
    }

    let userNotificationCenter: any UNUserNotificationCenterProtocol
    let mode: Mode
    let onSave: () -> Void

    enum Mode {
        case add
        case edit(UNNotificationRequest)
    }

    enum TriggerType {
        case timeInterval(UNTimeIntervalNotificationTrigger)
        case calendar(UNCalendarNotificationTrigger)
        case location(UNLocationNotificationTrigger)

        var trigger: UNNotificationTrigger {
            switch self {
            case .timeInterval(let unTimeIntervalNotificationTrigger):
                unTimeIntervalNotificationTrigger
            case .calendar(let unCalendarNotificationTrigger):
                unCalendarNotificationTrigger
            case .location(let location):
                location
            }
        }
    }

    init(
        userNotificationCenter: some UNUserNotificationCenterProtocol,
        mode: Mode,
        onSave: @escaping () -> Void
    ) {
        self.userNotificationCenter = userNotificationCenter
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .add:
            let content = UNNotificationContent()
            _identifier = State(initialValue: "")
            _title = State(initialValue: content.title)
            _subtitle = State(initialValue: content.subtitle)
            _bodyString = State(initialValue: content.body)
            _attachments = State(initialValue: content.attachments.map { ($0.identifier, $0.url) })
            _badge = State(initialValue: content.badge?.intValue)
            _categoryIdentifier = State(initialValue: content.categoryIdentifier)
            _interruptionLevel = State(initialValue: content.interruptionLevel.rawValue)
            _launchImageName = State(initialValue: content.launchImageName)
            _relevanceScore = State(initialValue: content.relevanceScore)
            _targetContentIdentifier = State(initialValue: content.targetContentIdentifier)
            _threadIdentifier = State(initialValue: content.threadIdentifier)
            _userInfoString = State(initialValue: "{}")
            if #available(iOS 16.0, *) {
                _filterCriteria = State(initialValue: content.filterCriteria)
            }
            var dateComponents = Calendar.current.dateComponents(
                in: .autoupdatingCurrent,
                from: Date()
            )
            dateComponents.hour = (dateComponents.hour ?? 0) + 1
            _triggerType = State(initialValue: .timeInterval(.init(timeInterval: 60, repeats: true)))
        case .edit(let request):
            _identifier = State(initialValue: request.identifier)
            _title = State(initialValue: request.content.title)
            _subtitle = State(initialValue: request.content.subtitle)
            _bodyString = State(initialValue: request.content.body)
            _attachments = State(initialValue: request.content.attachments.map { ($0.identifier, $0.url) })
            _badge = State(initialValue: request.content.badge?.intValue)
            _categoryIdentifier = State(initialValue: request.content.categoryIdentifier)
            _interruptionLevel = State(initialValue: request.content.interruptionLevel.rawValue)
            _launchImageName = State(initialValue: request.content.launchImageName)
            _relevanceScore = State(initialValue: request.content.relevanceScore)
            _targetContentIdentifier = State(initialValue: request.content.targetContentIdentifier)
            _threadIdentifier = State(initialValue: request.content.threadIdentifier)
            _userInfoString = State(
                initialValue: request.content.userInfo
                    .compactMapKeys { $0.base as? String }
                    .json()
            )
            if #available(iOS 16.0, *) {
                _filterCriteria = State(initialValue: request.content.filterCriteria)
            }
            _triggerType = State(initialValue: {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    return .calendar(trigger)
                } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    return .timeInterval(trigger)
                } else if let trigger = request.trigger as? UNLocationNotificationTrigger {
                    return .location(trigger)
                } else {
                    return nil
                }
            }())
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section("trigger") {
                    trigger
                }
                Section("identifier") {
                    TextField("identifier", text: $identifier)
                }
                Section("title") {
                    TextField("title", text: $title)
                }
                Section("subtitle") {
                    TextField("subtitle", text: $subtitle)
                }
                Section("body") {
                    TextField("body", text: $bodyString)
                }
                Section("user info") {
                    TextEditor(text: $userInfoString)
                }
                Section("badge") {
                    TextField(
                        "badge",
                        text: .init(
                            get: { badge?.description ?? "" },
                            set: {
                                if let newValue = Int($0) {
                                    self.badge = newValue
                                }
                            }
                        )
                    )
                }
                Section("category identifier") {
                    TextField("categoryIdentifier", text: $categoryIdentifier)
                }
                Section("filter criteria") {
                    TextField(
                        "filterCriteria",
                        text: .init(
                            get: { filterCriteria ?? "" },
                            set: { filterCriteria = $0 }
                        )
                    )
                }
                Section("interruption level") {
                    TextField(
                        "interruptionLevel",
                        text: .init(
                            get: { interruptionLevel.description },
                            set: {
                                if let newValue = Int($0) {
                                    interruptionLevel = UInt(newValue)
                                }
                            }
                        )
                    )
                }
                Section("launch image name") {
                    TextField("launch image name", text: $launchImageName)
                }
                Section("relevance score") {
                    TextField(
                        "relevance score",
                        text: .init(
                            get: { relevanceScore.description },
                            set: {
                                if let newValue = Double($0) {
                                    relevanceScore = newValue
                                }
                            }
                        )
                    )
                }
                Section("target content identifier") {
                    TextField(
                        "targetContentIdentifier",
                        text: .init(
                            get: { targetContentIdentifier ?? "" },
                            set: { targetContentIdentifier = $0 }
                        )
                    )
                }
                Section("thread identifier") {
                    TextField("threadIdentifier", text: $threadIdentifier)
                }
                if !attachments.isEmpty {
                    Section("Attachments") {
                        ForEach(attachments, id: \.identifier) { attachment in
                            HStack {
                                Text("identifier")
                                Spacer()
                                Text(attachment.identifier)
                            }
                            HStack {
                                Text("url")
                                Spacer()
                                Text(attachment.url.absoluteString)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { try await saveButtonTapped() }
                    }
                    .disabled(!isSaveButtonEnabled)
                }
            }
        }
    }

    @ViewBuilder
    private var trigger: some View {
        switch triggerType {
        case .timeInterval(let trigger):
            TextField(
                "timeInterval",
                text: .init(
                    get: { trigger.timeInterval.description },
                    set: {
                        if let newValue = Double($0) {
                            triggerType = .timeInterval(
                                UNTimeIntervalNotificationTrigger(
                                    timeInterval: trigger.repeats ? max(60, newValue) : newValue,
                                    repeats: trigger.repeats
                                )
                            )
                        }
                    }
                )
            )
            Toggle(
                "repeats",
                isOn: .init(
                    get: {
                        trigger.repeats
                    },
                    set: {
                        triggerType = .timeInterval(
                            UNTimeIntervalNotificationTrigger(
                                timeInterval: $0 ? max(60, trigger.timeInterval) : trigger.timeInterval,
                                repeats: $0
                            )
                        )
                    }
                )
            )
        case .calendar(let trigger):
            DatePicker(
                selection: .init(
                    get: {
                        trigger.dateComponents.date ?? Date()
                    },
                    set: {
                        let dateComponents = Calendar.current.dateComponents(
                            in: .autoupdatingCurrent,
                            from: $0
                        )
                        triggerType = .calendar(
                            UNCalendarNotificationTrigger(
                                dateMatching: dateComponents,
                                repeats: trigger.repeats
                            )
                        )
                    }
                ),
                displayedComponents: [.date, .hourAndMinute]
            ) {
                Text("Date")
            }
            Toggle(
                "repeats",
                isOn: .init(
                    get: {
                        trigger.repeats
                    },
                    set: {
                        triggerType = .calendar(
                            UNCalendarNotificationTrigger(
                                dateMatching: trigger.dateComponents,
                                repeats: $0
                            )
                        )
                    }
                )
            )

        case .location(let trigger):
            Toggle(
                "repeats",
                isOn: .init(
                    get: {
                        trigger.repeats
                    },
                    set: {
                        triggerType = .location(
                            UNLocationNotificationTrigger(
                                region: trigger.region,
                                repeats: $0
                            )
                        )
                    }
                )
            )
        case nil:
            EmptyView()
        }
    }

    private func saveButtonTapped() async throws {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: createNotificationContent(),
            trigger: triggerType?.trigger
        )
        switch mode {
        case .add:
            try await userNotificationCenter.add(request)
        case .edit:
            userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            try await userNotificationCenter.add(request)
        }
        dismiss()
        onSave()
    }

    private func createNotificationContent() -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = bodyString
        content.attachments = attachments.compactMap {
            try? UNNotificationAttachment(
                identifier: $0.identifier,
                url: $0.url
            )
        }
        if let badge {
            content.badge = NSNumber(integerLiteral: badge)
        }
        content.categoryIdentifier = categoryIdentifier
        if let level = UNNotificationInterruptionLevel(rawValue: interruptionLevel) {
            content.interruptionLevel = level
        }
        content.launchImageName = launchImageName
        content.relevanceScore = relevanceScore
        content.subtitle = subtitle
        content.targetContentIdentifier = targetContentIdentifier
        content.threadIdentifier = threadIdentifier
        content.userInfo = userInfo
        if #available(iOS 16.0, *) {
            content.filterCriteria = filterCriteria
        }
        return content
    }
}

#Preview {
    LocalNotificationEditor(
        userNotificationCenter: UNUserNotificationCenter.current(),
        mode: .add
    ) {}
}

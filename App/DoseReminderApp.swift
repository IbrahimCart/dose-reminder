import SwiftUI
import UserNotifications

@main
struct DoseReminderApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        UNUserNotificationCenter.current().setNotificationCategories([NotificationScheduler.category])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.doseGreen)
                .preferredColorScheme(.light)
                .environmentObject(model)
                .onAppear { notificationDelegate.model = model }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { model.refresh() }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        TabView {
            HomeView().tabItem { Label("Today", systemImage: "pills") }
            HistoryView().tabItem { Label("History", systemImage: "list.bullet") }
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .overlay {
            if let id = model.confettiID { ConfettiView().id(id) }
        }
    }
}

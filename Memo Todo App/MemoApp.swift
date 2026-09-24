import Sparkle
import SwiftUI

@main
struct MemoApp: App {
    @State private var store = TodoStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    var body: some Scene {
        MenuBarExtra {
            TodoMenuView(store: store)
        } label: {
            HStack(spacing: 4) {
                if let systemImageName = store.menuBarIconStyle.systemImageName {
                    Image(systemName: systemImageName)
                } else {
                    Image("MenuBarIcon")
                }
                if store.showCounter && !store.items.isEmpty {
                    Text("\(store.completedCount)/\(store.items.count)")
                }
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store, updaterController: updaterController)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

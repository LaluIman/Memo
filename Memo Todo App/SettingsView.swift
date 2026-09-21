import SwiftUI

struct SettingsView: View {
    @Bindable var store: TodoStore

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("General") {
                    Toggle("Launch at Startup", isOn: $store.launchAtStartup)
                        .toggleStyle(.checkbox)
                    Toggle("Show Counter in Menu Bar", isOn: $store.showCounter)
                        .toggleStyle(.checkbox)
                    Toggle("Play Sound on Task Completion", isOn: $store.playSoundOnCompletion)
                        .toggleStyle(.checkbox)

                    Slider(value: $store.soundVolume, in: 0...1) {
                        Text("Sound Volume")
                    }
                    .disabled(!store.playSoundOnCompletion)
                }

                Section("Task Defaults") {
                    Picker("Menu Bar Icon", selection: $store.menuBarIconStyle) {
                        ForEach(MenuBarIconStyle.allCases) { style in
                            Label {
                                Text(style.label)
                            } icon: {
                                if let systemImageName = style.systemImageName {
                                    Image(systemName: systemImageName)
                                } else {
                                    Image("MenuBarIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 16, height: 16)
                                }
                            }
                            .tag(style)
                        }
                    }

                    Picker("Default Priority", selection: $store.defaultPriority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Label {
                                Text(priority.label)
                            } icon: {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 8, height: 8)
                            }
                            .tag(priority)
                        }
                    }

                    Picker("When Task Completed", selection: $store.completedTaskBehavior) {
                        ForEach(CompletedTaskBehavior.allCases) { behavior in
                            Text(behavior.label).tag(behavior)
                        }
                    }
                }
            }
            .formStyle(.grouped)

            VStack(spacing: 2) {
                Text("\(Bundle.main.appName) \(Bundle.main.appVersionString)")
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text("made by")
                        .foregroundStyle(.secondary)
                    
                    Link("Lalu Iman", destination: URL(string: "https://github.com/LaluIman")!)
                }
            }
            .font(.caption)
            .padding(.bottom, 14)
        }
        .frame(width: 420)
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

private extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
    }

    var appVersionString: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "v\(version) (\(build))"
    }
}

#Preview {
    SettingsView(store: TodoStore())
}

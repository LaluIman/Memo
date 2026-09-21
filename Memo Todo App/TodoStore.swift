import AppKit
import Observation
import ServiceManagement

@Observable
final class TodoStore {
    var items: [TodoItem] = [] {
        didSet { save() }
    }

    var launchAtStartup: Bool {
        didSet {
            guard launchAtStartup != oldValue else { return }
            setLaunchAtStartup(launchAtStartup)
        }
    }

    var menuBarIconStyle: MenuBarIconStyle {
        didSet {
            guard menuBarIconStyle != oldValue else { return }
            UserDefaults.standard.set(menuBarIconStyle.rawValue, forKey: menuBarIconStyleKey)
        }
    }

    var showCounter: Bool {
        didSet {
            guard showCounter != oldValue else { return }
            UserDefaults.standard.set(showCounter, forKey: showCounterKey)
        }
    }

    var defaultPriority: TaskPriority {
        didSet {
            guard defaultPriority != oldValue else { return }
            UserDefaults.standard.set(defaultPriority.rawValue, forKey: defaultPriorityKey)
        }
    }

    var completedTaskBehavior: CompletedTaskBehavior {
        didSet {
            guard completedTaskBehavior != oldValue else { return }
            UserDefaults.standard.set(completedTaskBehavior.rawValue, forKey: completedTaskBehaviorKey)
        }
    }

    var playSoundOnCompletion: Bool {
        didSet {
            guard playSoundOnCompletion != oldValue else { return }
            UserDefaults.standard.set(playSoundOnCompletion, forKey: playSoundOnCompletionKey)
        }
    }

    var soundVolume: Double {
        didSet {
            guard soundVolume != oldValue else { return }
            UserDefaults.standard.set(soundVolume, forKey: soundVolumeKey)
        }
    }

    var completedCount: Int {
        items.filter(\.isCompleted).count
    }

    private let defaultsKey = "todoItems"
    private let menuBarIconStyleKey = "menuBarIconStyle"
    private let showCounterKey = "showCounter"
    private let defaultPriorityKey = "defaultPriority"
    private let completedTaskBehaviorKey = "completedTaskBehavior"
    private let playSoundOnCompletionKey = "playSoundOnCompletion"
    private let soundVolumeKey = "soundVolume"
    @ObservationIgnored
    private lazy var completionSound = NSSound(named: "Glass")

    init() {
        launchAtStartup = SMAppService.mainApp.status == .enabled
        if let rawValue = UserDefaults.standard.string(forKey: menuBarIconStyleKey),
           let style = MenuBarIconStyle(rawValue: rawValue) {
            menuBarIconStyle = style
        } else {
            menuBarIconStyle = .custom
        }
        showCounter = UserDefaults.standard.object(forKey: showCounterKey) as? Bool ?? true
        if let rawValue = UserDefaults.standard.string(forKey: defaultPriorityKey),
           let priority = TaskPriority(rawValue: rawValue) {
            defaultPriority = priority
        } else {
            defaultPriority = .medium
        }
        if let rawValue = UserDefaults.standard.string(forKey: completedTaskBehaviorKey),
           let behavior = CompletedTaskBehavior(rawValue: rawValue) {
            completedTaskBehavior = behavior
        } else {
            completedTaskBehavior = .keepInPlace
        }
        playSoundOnCompletion = UserDefaults.standard.object(forKey: playSoundOnCompletionKey) as? Bool ?? false
        soundVolume = UserDefaults.standard.object(forKey: soundVolumeKey) as? Double ?? 1.0
        load()
    }

    func addItem(_ title: String, priority: TaskPriority) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(title: trimmed, priority: priority))
    }

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isCompleted.toggle()
        let isNowCompleted = items[index].isCompleted

        if isNowCompleted, playSoundOnCompletion {
            playCompletionSound()
        }

        if isNowCompleted, completedTaskBehavior == .moveToBottom {
            let moved = items.remove(at: index)
            items.append(moved)
        }
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearCompleted() {
        items.removeAll { $0.isCompleted }
    }

    func updateTitle(of item: TodoItem, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].title = trimmed
    }

    private func playCompletionSound() {
        guard let completionSound else { return }
        completionSound.stop()
        completionSound.volume = Float(soundVolume)
        completionSound.play()
    }

    private func setLaunchAtStartup(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at startup: \(error)")
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            items = []
            return
        }
        items = decoded
    }
}

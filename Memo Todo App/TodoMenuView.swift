import SwiftUI

struct TodoMenuView: View {
    @Bindable var store: TodoStore
    @State private var newItemTitle = ""
    @State private var newItemPriority: TaskPriority = .medium
    @FocusState private var isTextFieldFocused: Bool

    @State private var editingItemID: TodoItem.ID?
    @State private var editingTitle = ""
    @FocusState private var focusedItemID: TodoItem.ID?

    @Environment(\.openSettings) private var openSettings

    private var displayedItems: [TodoItem] {
        guard store.completedTaskBehavior == .hideImmediately else { return store.items }
        return store.items.filter { !$0.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if displayedItems.isEmpty {
                Text("No items yet")
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(displayedItems) { item in
                        row(for: item)
                    }
                    .reorderable()
                }
                .reorderContainer(for: TodoItem.self) { difference in
                    applyReorder(difference)
                }
            }

            Divider()

            HStack {
                TextField("Add new item...", text: $newItemTitle)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onSubmit(addItem)

                Picker("", selection: $newItemPriority) {
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
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 110)

                Button("Add", action: addItem)
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(8)

            Divider()

            Button("Clear Completed") {
                store.clearCompleted()
            }
            .buttonStyle(.plain)
            .disabled(store.completedCount == 0)
            .padding(8)

            Divider()

            Button("Settings...") {
                let success = NSApp.setActivationPolicy(.regular)
                print("setActivationPolicy(.regular) succeeded: \(success)")
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            }
            .buttonStyle(.plain)
            .padding(8)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
            .padding(8)
        }
        .frame(width: 340)
        .padding(.top, 8)
        .onChange(of: focusedItemID) { oldValue, newValue in
            guard let editingItemID, oldValue == editingItemID, newValue != editingItemID,
                  let item = store.items.first(where: { $0.id == editingItemID }) else { return }
            commitEdit(for: item)
        }
        .onAppear {
            newItemPriority = store.defaultPriority
        }
    }

    private func row(for item: TodoItem) -> some View {
        HStack {
            Button {
                store.toggle(item)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.isCompleted ? Color.accentColor : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(item.isCompleted ? Color.clear : Color.secondary, lineWidth: 1.5)
                        )
                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 16, height: 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Circle()
                .fill(item.priority.color)
                .frame(width: 8, height: 8)

            if editingItemID == item.id {
                TextField("Title", text: $editingTitle)
                    .textFieldStyle(.plain)
                    .focused($focusedItemID, equals: item.id)
                    .onSubmit { commitEdit(for: item) }
            } else {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                    .contentShape(Rectangle())
                    .onTapGesture { startEditing(item) }
            }

            Spacer()

            Button {
                store.delete(item)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func addItem() {
        store.addItem(newItemTitle, priority: newItemPriority)
        newItemTitle = ""
        newItemPriority = store.defaultPriority
        isTextFieldFocused = true
    }

    private func startEditing(_ item: TodoItem) {
        editingItemID = item.id
        editingTitle = item.title
        focusedItemID = item.id
    }

    private func commitEdit(for item: TodoItem) {
        store.updateTitle(of: item, to: editingTitle)
        if editingItemID == item.id {
            editingItemID = nil
        }
    }

    private func applyReorder(_ difference: ReorderDifference<TodoItem.ID, ReorderableSingleCollectionIdentifier>) {
        let movingIDs = Set(difference.sources)
        guard !movingIDs.isEmpty else { return }

        var moved: [TodoItem] = []
        store.items.removeAll { item in
            guard movingIDs.contains(item.id) else { return false }
            moved.append(item)
            return true
        }

        switch difference.destination.position {
        case .before(let id):
            let index = store.items.firstIndex { $0.id == id } ?? store.items.endIndex
            store.items.insert(contentsOf: moved, at: index)
        case .end:
            store.items.append(contentsOf: moved)
        }
    }
}

#Preview {
    let store = TodoStore()
    return TodoMenuView(store: store)
}

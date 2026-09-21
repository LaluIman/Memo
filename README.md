<div align="center">
  <img width="96" height="96" alt="Memo app icon" src="https://github.com/user-attachments/assets/8278e3cf-a1fa-4129-9daa-8a9de933f9be" />
  <h1>Memo</h1>
  <h3>To-dos that live in your menu bar</h3>
  <p>
    <img src="https://img.shields.io/badge/macOS-27%2B-lightgrey" alt="macOS 27+" />
    <img src="https://img.shields.io/badge/Swift-SwiftUI-orange" alt="Swift SwiftUI" />
    <img src="https://img.shields.io/badge/license-MIT-green" alt="License: MIT" />
  </p>
  <br>
  <img width="528" alt="Memo menu bar dropdown showing a task list with priorities" src="https://github.com/user-attachments/assets/35fc68db-27f9-4ee0-aa03-f3d4816f0354" />
  <br>
  <br>
</div>

Memo turns your macOS menu bar into a running task list — no Dock icon, no window to manage, just a click away whenever you need it. Add tasks, set a priority, give them a due date, drag to reorder, and check them off with a sound and a satisfying tick. Decide what happens to finished items — keep them in place, send them to the bottom, or hide them on completion — and pick the menu bar icon and counter that fit how you like to work.

## Installation

Memo is distributed as source only — it isn't notarized, so a prebuilt download would be blocked by Gatekeeper. Build it yourself with Xcode:

```bash
git clone https://github.com/LaluIman/Memo.git
cd Memo
open "Memo Todo App.xcodeproj"
```

Then hit **Run** in Xcode (⌘R). The app is signed with your own Apple ID during the build, so it launches immediately with no security warnings.

**Requirements:**
- macOS 27 Golden Gate or later
- Apple Silicon
- Xcode 26 or later, with a free Apple ID signed in (Xcode → Settings → Accounts)

## Features

### Core

| Feature | Description |
| --- | --- |
| Menu Bar Access | Manage your entire to-do list from a dropdown in the macOS menu bar — no Dock icon, no window. |
| Quick Add | Add new tasks instantly via a text field with Enter-to-submit. |
| Inline Editing | Click any task title to rename it in place. |
| Drag-to-Reorder | Reorder tasks by dragging them within the list. |
| Task Priorities | Assign each task a priority (Low, Medium, High, Critical), shown with a color indicator. |
| Default Priority | Set the priority automatically applied to new tasks. |
| Due Dates | Give any task a due date via a quick date picker. Shows as "Today," "Tomorrow," or the date, and turns red when overdue. |

### Completion

| Feature | Description |
| --- | --- |
| Task Completion | Toggle tasks as done with one click, with configurable behavior: Keep in Place, Move to Bottom, or Hide Immediately. |
| Clear Completed | Remove all completed tasks in one click. |
| Completion Counter | Optionally show a "completed/total" counter directly in the menu bar icon. |
| Sound Feedback | Optional sound effect on task completion, with adjustable volume. |

### System

| Feature | Description |
| --- | --- |
| Customizable Icon | Choose from several menu bar icon styles (Default, Checklist, Checkmark Circle, List, Star, Tray). |
| Launch at Startup | Optionally launch the app automatically at login. |
| Persistent Storage | Tasks and preferences are saved locally and restored between launches. |
| Send Feedback | Report a bug, request a feature, or ask a question directly from Settings — no need to leave the app. |


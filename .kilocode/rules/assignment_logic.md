# Flodo Assignment: Task Management App

## 1. Technical Stack
- **Frontend:** Flutter & Dart
- **Backend:** Python (FastAPI)
- **Database:** PostgreSQL
- **Connection:** Flutter must connect to FastAPI via HTTP (use 10.0.2.2 for emulator).

## 2. Core Constraints (Strict)
- **Task Model:** Must have Title, Description, Due Date, Status (To-Do, In Progress, Done), and Blocked By (Optional ID).
- **Dependency Rule:** If Task B is blocked by Task A, Task B's UI must be "greyed out" until Task A is "Done".
- **Simulation Rule:** ALL Create/Update actions must have a **2-second artificial delay**.
- **UX Rule:** During the 2-second delay, show a loading state and disable the "Save" button to prevent double-tapping.

## 3. Specific Features
- **Drafts:** Use `shared_preferences` to persist Task Creation text against app minimization/accidental closure.
- **Search & Filter:** - Title Search: **Must be Debounced (300ms)** to prevent API spam.
    - Highlight: Match text within results must be visually highlighted.
    - Status Filter: Dropdown toggle on the main screen.
- **Recurring Tasks:** - Add a "Recurring" toggle (Daily/Weekly) to Creation Screen.
    - Logic: When a recurring task is set to "Done", automatically POST a new task with an incremented Due Date.
- **Persistent Drag-and-Drop:** - Implement a `ReorderableListView`.
    - Backend: Add a `position` (Integer) column to the Task model.
    - Sync: Every reorder must trigger a backend update to save the new sequence.
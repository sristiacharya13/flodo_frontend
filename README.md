# Flodo Mobile App 📱

A reactive task management application built with Flutter, focusing on smooth state management and sophisticated user feedback loops.

## 📝 Project Description
Flodo provides an "Optimistic UI" experience. It instantly reflects status changes locally while elegantly handling a high-latency backend through provider-based state synchronization.

## 🛠️ Tech Stack
* **Framework:** Flutter SDK
* **State Management:** Provider
* **Networking:** Http / JSON API
* **UX:** Material 3 & Haptic Feedback

## ⚙️ Setup & Installation

### 1. Prerequisites 
Ensure the Flutter SDK is installed and configured in your PATH.

### 2. Clone & Install
```bash
git clone https://github.com/sristiacharya13/flodo_frontend.git
cd flodo_frontend
flutter pub get
```

### 3. Connection Configuration
To connect your mobile device to the backend, update the baseUrl in lib/services/api_service.dart with your machine's Local IP:
```bash
static const String baseUrl = 'http://192.168.1.XX:8000';
```

### 4. Launch
  ```bash
  flutter run
```

## 🎯 Track A & Stretch Goals
* **Debounced Autocomplete Search:** Implemented debounced autocomplete search (300ms delay) with real-time filtering and highlighted matches in task titles.
* **Recurring Tasks Logic:** Built recurring task logic to auto-generate the next task cycle upon completion while preserving the original record.
* **Persistent Drag-and-Drop:** Enabled persistent drag-and-drop task reordering with database synchronization.

## 🧠 AI Implementation & Development Report
**Agents used**
* **Google Gemini:** Used for complex logic synchronization, Flutter Provider state management, and debugging race conditions.
* **Kilo Code (Grok Code Fast 1):** Utilized for initial boilerplate generation and UI component structuring.
  
### **The "Source of Truth" Method**
To prevent AI hallucinations and ensure "Elite" feature compliance, I provided the `assignment_logic.md` file as the primary grounding document.
**Core Instruction:** "Analyze the `assignment_logic.md` file in the root directory. All implementation including the 2-second simulated latency, debounced search, and recurring task logic must adhere strictly to these rules before proposing architecture."

### AI Usage and Debugging
**Prompts that gave me the most helpful code**  
"Implemetation: Recurring Tasks Logic: Add a "Recurring" toggle (e.g., Daily or Weekly) to the task creation screen. When a recurring task is marked as "Done", the app should automatically generate a duplicate of that task with the Due Date pushed forward to the next cycle, while keeping the original task logged as completed.
Issue:

When testing via Swagger (backend), the recurring logic works perfectly.
However, from the frontend:
I create a task with status ToDo/InProgress and enable recurrence.
When I update the task status to Done, the duplicate task is not created and displayed
Expected Behavior:
Updating a recurring task to Done from the frontend should trigger the same logic as Swagger and create/display the next recurring task."

**Where the AI failed and how I solved it**  
The AI initially assumed a standard notifyListeners() call was enough. I had to manually intervene and implement a 2.5-second Future.delayed buffer in the TaskProvider to "cover" the backend's artificial latency, ensuring the UI stayed in sync with background database transactions.
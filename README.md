# Flodo AI Task Management App

## Track & Stretch Goal
- **Track Chosen:** Track A (Full-Stack Builder)
  - Frontend: Flutter & Dart
  - Backend: Python (FastAPI)
  - Database: SQLite
- **Stretch Goal Chosen:** Debounced Autocomplete Search.
  - The search text field uses a 300ms debounce (via Riverpod `Timer`) to prevent spamming the backend API.
  - Search queries are visually highlighted (yellow background) in the task titles using `RichText`.

## Features implemented
- Clean, modern, responsive UI using Google Fonts (Inter) and custom Card designs.
- Required Data Model fields (Title, Description, Status, DueDate, BlockedById).
- **CRUD:** Complete Create, Read, Update, Delete functionality communicating via `dio`.
- **Drafts:** Entering details in the creation screen and swiping back caches the draft globally via a separate Riverpod provider.
- **Search & Filter:** Reactive status dropdowns and debounced text search.
- **Task Blocking:** If a task is blocked, it's greyed out (`disabledColor`), stripped of elevation, and shows a red "Blocked by: [Task]" warning. A task cannot be marked done until the blocker is done.
- **Forced 2-second delay:** The backend simulates a 2-second delay on Create/Update. The frontend shows a non-blocking UI loading indicator and handles duplicate submissions.

## Setup Instructions

### 1. Backend (FastAPI) Setup
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn sqlalchemy pydantic
uvicorn main:app --reload
```
The backend will run at `http://127.0.0.1:8000`.

### 2. Frontend (Flutter) Setup
Open a new terminal.
```bash
cd flodo_frontend
flutter pub get
flutter run
```

## AI Usage Report
I utilized Antigravity, an agentic AI coding assistant, to scaffold and implement the application.
- **Most helpful code:** Scaffolding the entire Riverpod decoupled architecture (`api_service`, `task_provider`, `draft_provider`). It provided extremely clean separation of concerns out of the box.
- **Hallucinations / Bad Code:** The AI hallucinated string interpolation literals in Dart (`\${e.message}` instead of `${e.message}`) because of its python shell string generator escaping. It also initially provided deprecated Flutter 2/3 widgets (`WillPopScope`, `StateNotifier`). It fixed these natively by automatically running `flutter analyze` and replacing the deprecated widgets with `PopScope` and `Notifier`.
